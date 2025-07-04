#!/usr/bin/env python3

"""
Package cleanup script for HiFiBerry OS
This script removes unnecessary packages to clean up the Debian installation
"""

import os
import sys
import argparse
import subprocess
import logging
from pathlib import Path


def setup_logging(verbose=False):
    """Setup logging configuration"""
    level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(
        level=level,
        format='%(levelname)s: %(message)s',
        stream=sys.stderr
    )


def read_package_list(config_file):
    """
    Read package list from configuration file
    
    Args:
        config_file: Path to the configuration file
        
    Returns:
        List of package names
    """
    packages = []
    try:
        with open(config_file, 'r') as f:
            for line in f:
                line = line.strip()
                # Skip comments and empty lines
                if line and not line.startswith('#'):
                    packages.append(line)
        return packages
    except FileNotFoundError:
        logging.error(f"Configuration file not found: {config_file}")
        return []
    except Exception as e:
        logging.error(f"Error reading {config_file}: {e}")
        return []


def is_package_installed(package):
    """
    Check if a package is installed
    
    Args:
        package: Package name to check
        
    Returns:
        True if installed, False otherwise
    """
    try:
        result = subprocess.run(
            ['dpkg-query', '-W', '-f=${Status}', package],
            capture_output=True,
            text=True,
            check=False
        )
        return 'ok installed' in result.stdout
    except Exception:
        return False


def check_package_dependencies(package, verbose=False):
    """
    Check if a package has other packages depending on it
    This uses a more reliable method by checking what would happen if we try to remove the package
    
    Args:
        package: Package name to check
        verbose: Enable verbose output
        
    Returns:
        List of packages that depend on this package
    """
    try:
        # Use apt-get with --simulate to see what would be removed
        result = subprocess.run(
            ['apt-get', 'remove', '--simulate', package],
            capture_output=True,
            text=True,
            check=False
        )
        
        if result.returncode != 0:
            # If apt-get fails, the package likely has dependencies
            if verbose:
                logging.info(f"Package {package} has dependency issues (apt-get failed)")
            return ['dependency-conflict']
        
        # Parse the output to see what would be removed
        dependents = []
        lines = result.stdout.strip().split('\n')
        
        for line in lines:
            line = line.strip()
            if line.startswith('Remv '):
                # Extract package name from "Remv package-name [version]"
                parts = line.split()
                if len(parts) >= 2:
                    pkg_name = parts[1]
                    if pkg_name != package:
                        dependents.append(pkg_name)
        
        if verbose and dependents:
            logging.info(f"Removing {package} would also remove: {', '.join(dependents)}")
        
        return dependents
        
    except Exception as e:
        if verbose:
            logging.warning(f"Error checking dependencies for {package}: {e}")
        return ['error-checking']


def is_package_safe_to_remove(package, verbose=False):
    """
    Check if a package is safe to remove (no essential dependencies)
    
    Args:
        package: Package name to check
        verbose: Enable verbose output
        
    Returns:
        True if safe to remove, False otherwise
    """
    try:
        # Check if package is marked as essential
        result = subprocess.run(
            ['dpkg-query', '-W', '-f=${Essential}', package],
            capture_output=True,
            text=True,
            check=False
        )
        
        if 'yes' in result.stdout.lower():
            if verbose:
                logging.warning(f"Package {package} is marked as essential")
            return False
        
        # Check if package has ANY dependencies (be very conservative)
        dependents = check_package_dependencies(package, verbose)
        
        # If ANY packages depend on this one, don't remove it
        if dependents:
            if verbose:
                logging.warning(f"Package {package} has {len(dependents)} dependents: {', '.join(dependents[:3])}{'...' if len(dependents) > 3 else ''}")
            return False
        
        # Check for common essential packages patterns
        essential_packages = [
            'base-files', 'base-passwd', 'bash', 'coreutils', 'dash', 'debconf',
            'debian-archive-keyring', 'dpkg', 'e2fsprogs', 'findutils',
            'grep', 'gzip', 'hostname', 'init', 'login', 'mount',
            'passwd', 'perl-base', 'sed', 'sysvinit-utils', 'tar', 'util-linux',
            'systemd', 'dbus', 'udev', 'apt', 'libc6', 'libgcc-s1',
            'libstdc++6', 'zlib1g', 'ncurses-base', 'ncurses-bin'
        ]
        
        if package.lower() in essential_packages:
            if verbose:
                logging.warning(f"Package {package} is in essential packages list")
            return False
        
        return True
        
    except Exception as e:
        if verbose:
            logging.warning(f"Error checking if {package} is safe to remove: {e}")
        # If we can't determine, err on the side of caution
        return False


def get_installed_packages(packages, verbose=False):
    """
    Filter package list to only include installed packages that are safe to remove
    
    Args:
        packages: List of package names to check
        verbose: Enable verbose output
        
    Returns:
        List of installed package names that are safe to remove
    """
    installed = []
    unsafe_packages = []
    
    for package in packages:
        if not package:  # Skip empty package names
            continue
            
        if is_package_installed(package):
            dependents = check_package_dependencies(package, verbose)
            if not dependents and is_package_safe_to_remove(package, verbose):
                installed.append(package)
                if verbose:
                    logging.info(f"Found installed and safe: {package}")
            else:
                unsafe_packages.append((package, dependents))
                if verbose:
                    logging.warning(f"Found installed but unsafe: {package}")
        else:
            if verbose:
                logging.info(f"Not installed: {package}")
    
    if unsafe_packages:
        print(f"\nSKIPPED: {len(unsafe_packages)} packages that are unsafe to remove:")
        for package, dependents in unsafe_packages:
            if dependents:
                if dependents == ['dependency-conflict']:
                    print(f"  - {package} (has dependency conflicts)")
                elif dependents == ['error-checking']:
                    print(f"  - {package} (unable to verify dependencies)")
                else:
                    # Show first few dependents to avoid overwhelming output
                    if len(dependents) <= 3:
                        deps_str = ", ".join(dependents)
                    else:
                        deps_str = f"{', '.join(dependents[:3])} (and {len(dependents)-3} more)"
                    print(f"  - {package} (removing would also remove: {deps_str})")
            else:
                print(f"  - {package} (system-critical or essential)")
    
    return installed


def remove_packages(packages, dry_run=False):
    """
    Remove packages using apt-get
    
    Args:
        packages: List of package names to remove
        dry_run: If True, only show what would be done
        
    Returns:
        True if successful, False otherwise
    """
    if dry_run:
        print("\nDRY RUN: Would remove the above packages")
        print("Commands that would be executed:")
        print(f"  apt-get remove --purge -y {' '.join(packages)}")
        print("  apt-get autoremove -y")
        print("  apt-get autoclean")
        return True
    
    # First, simulate the removal to check for dependency issues
    print("\nChecking for dependency conflicts...")
    try:
        result = subprocess.run(
            ['apt-get', 'remove', '--purge', '--simulate'] + packages,
            capture_output=True,
            text=True,
            check=False
        )
        
        if result.returncode != 0:
            logging.error("Dependency conflicts detected during simulation:")
            print(result.stderr)
            return False
        
        print("Dependency check passed.")
        
    except Exception as e:
        logging.error(f"Error during dependency check: {e}")
        return False
    
    # Remove packages
    print("\nRemoving packages...")
    try:
        result = subprocess.run(
            ['apt-get', 'remove', '--purge', '-y'] + packages,
            check=False
        )
        
        if result.returncode != 0:
            logging.error("Failed to remove some packages")
            return False
        
        print("Packages removed successfully.")
        
    except Exception as e:
        logging.error(f"Error removing packages: {e}")
        return False
    
    # Clean up dependencies
    print("\nRemoving unused dependencies...")
    try:
        result = subprocess.run(['apt-get', 'autoremove', '-y'], check=False)
        if result.returncode == 0:
            print("Unused dependencies removed successfully.")
        else:
            print("Warning: Failed to remove some unused dependencies.")
    except Exception as e:
        logging.warning(f"Error removing dependencies: {e}")
    
    # Clean package cache
    print("\nCleaning package cache...")
    try:
        result = subprocess.run(['apt-get', 'autoclean'], check=False)
        if result.returncode == 0:
            print("Package cache cleaned successfully.")
        else:
            print("Warning: Failed to clean package cache.")
    except Exception as e:
        logging.warning(f"Error cleaning cache: {e}")
    
    return True


def check_root_privileges():
    """
    Check if the script is running as root
    
    Returns:
        True if running as root, False otherwise
    """
    if os.geteuid() != 0:
        logging.error("This script must be run as root (use sudo)")
        return False
    return True


def main():
    """Main function"""
    # Determine default config file path
    script_dir = Path(__file__).parent
    local_config = script_dir / "cleanup-packages.conf"
    default_config = "/etc/hifiberry/baseconfig/cleanup-packages.conf"
    
    # Use local config if it exists, otherwise use system config
    if local_config.exists():
        default_config_path = str(local_config)
    else:
        default_config_path = default_config
    
    parser = argparse.ArgumentParser(
        description='Remove unnecessary packages from HiFiBerry OS'
    )
    
    parser.add_argument(
        '-c', '--config',
        default=default_config_path,
        help=f'Use specified config file (default: {default_config_path})'
    )
    
    parser.add_argument(
        '-n', '--dry-run',
        action='store_true',
        help='Show what would be removed without actually removing'
    )
    
    parser.add_argument(
        '-f', '--force',
        action='store_true',
        help='Skip confirmation prompts (does not override safety checks)'
    )
    
    parser.add_argument(
        '-v', '--verbose',
        action='store_true',
        help='Enable verbose output'
    )
    
    args = parser.parse_args()
    
    # Setup logging
    setup_logging(args.verbose)
    
    # Check if running as root (required for package removal)
    if not args.dry_run and not check_root_privileges():
        return 1
    
    # Check if config file exists
    if not os.path.exists(args.config):
        logging.error(f"Configuration file not found: {args.config}")
        return 1
    
    print("Package cleanup script for HiFiBerry OS")
    print(f"Configuration file: {args.config}")
    
    # Read package list
    packages = read_package_list(args.config)
    if not packages:
        print("No packages found in configuration file")
        return 0
    
    print(f"Found {len(packages)} packages to potentially remove")
    
    if args.verbose:
        print("Packages to check:", ', '.join(packages))
        print("Debug: Package list:")
        for i, package in enumerate(packages):
            print(f"  [{i}]: '{package}'")
    
    # Check which packages are installed
    installed_packages = get_installed_packages(packages, args.verbose)
    
    if not installed_packages:
        print("No packages from the cleanup list are currently installed.")
        return 0
    
    print(f"\nFound {len(installed_packages)} installed packages that can be removed:")
    for package in installed_packages:
        print(f"  - {package}")
    
    # Confirmation prompt unless --force or --dry-run is used
    if not args.force and not args.dry_run:
        try:
            response = input("\nDo you want to remove these packages? [y/N]: ").strip().lower()
            if response not in ['y', 'yes']:
                print("Operation cancelled.")
                return 0
        except (EOFError, KeyboardInterrupt):
            print("\nOperation cancelled by user")
            return 0
    
    # Remove packages
    if remove_packages(installed_packages, args.dry_run):
        if not args.dry_run:
            print(f"\nPackage cleanup completed successfully.")
            print("System cleanup summary:")
            print(f"  - Removed {len(installed_packages)} packages")
            print("  - Cleaned up unused dependencies")
            print("  - Cleaned package cache")
        return 0
    else:
        logging.error("Package cleanup failed")
        return 1


if __name__ == "__main__":
    sys.exit(main())
