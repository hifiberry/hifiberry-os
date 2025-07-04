#!/usr/bin/env python3
"""
HiFiBerry Base Configuration Script

This script handles:
1. Enabling and starting systemd services listed in services.conf
2. Overwriting configuration files based on configfiles.conf mappings
"""

import os
import sys
import argparse
import subprocess
import logging
import shutil
import uuid
from pathlib import Path


def setup_logging(verbose=False):
    """Setup logging configuration"""
    level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(
        level=level,
        format='%(levelname)s: %(message)s',
        stream=sys.stderr
    )


def read_config_file(config_path):
    """
    Read a configuration file and return non-empty, non-comment lines
    
    Args:
        config_path: Path to the configuration file
        
    Returns:
        List of configuration lines
    """
    try:
        with open(config_path, 'r') as f:
            lines = []
            for line in f:
                line = line.strip()
                if line and not line.startswith('#'):
                    lines.append(line)
            return lines
    except FileNotFoundError:
        logging.error(f"Configuration file not found: {config_path}")
        return []
    except Exception as e:
        logging.error(f"Error reading {config_path}: {e}")
        return []


def enable_and_start_service(service_name):
    """
    Enable and start a systemd service
    
    Args:
        service_name: Name of the systemd service
        
    Returns:
        True if successful, False otherwise
    """
    try:
        # Enable the service
        result = subprocess.run(
            ['systemctl', 'enable', service_name],
            capture_output=True,
            text=True,
            check=False
        )
        
        if result.returncode != 0:
            logging.warning(f"Failed to enable {service_name}: {result.stderr.strip()}")
            return False
        
        logging.info(f"Enabled service: {service_name}")
        
        # Start the service
        result = subprocess.run(
            ['systemctl', 'start', service_name],
            capture_output=True,
            text=True,
            check=False
        )
        
        if result.returncode != 0:
            logging.warning(f"Failed to start {service_name}: {result.stderr.strip()}")
            return False
        
        logging.info(f"Started service: {service_name}")
        return True
        
    except Exception as e:
        logging.error(f"Error handling service {service_name}: {e}")
        return False


def handle_services(services_conf_path):
    """
    Process services.conf and enable/start all listed services
    
    Args:
        services_conf_path: Path to services.conf file
        
    Returns:
        Number of successfully processed services
    """
    services = read_config_file(services_conf_path)
    if not services:
        logging.warning("No services found in services.conf")
        return 0
    
    logging.info(f"Processing {len(services)} services from {services_conf_path}")
    
    success_count = 0
    for service in services:
        if enable_and_start_service(service):
            success_count += 1
    
    logging.info(f"Successfully processed {success_count}/{len(services)} services")
    return success_count


def confirm_overwrite(config_file, original_file, force=False):
    """
    Ask user for confirmation before overwriting a file
    
    Args:
        config_file: Target configuration file
        original_file: Source file to copy from
        force: If True, skip confirmation
        
    Returns:
        True if should proceed, False otherwise
    """
    if force:
        return True
    
    if not os.path.exists(config_file):
        logging.info(f"Target file {config_file} does not exist, will create it")
        return True
    
    try:
        response = input(f"Overwrite {config_file} with {original_file}? [y/N]: ").strip().lower()
        return response in ['y', 'yes']
    except (EOFError, KeyboardInterrupt):
        print("\nOperation cancelled by user")
        return False


def copy_config_file(config_file, original_file):
    """
    Copy original file to config file location using Python's shutil
    
    Args:
        config_file: Target configuration file path
        original_file: Source file path
        
    Returns:
        True if successful, False otherwise
    """
    try:
        # Create target directory if it doesn't exist
        target_dir = os.path.dirname(config_file)
        if target_dir:
            os.makedirs(target_dir, exist_ok=True)
        
        # Copy the file using Python's shutil
        shutil.copy2(original_file, config_file)
        logging.info(f"Copied {original_file} to {config_file}")
        return True
        
    except Exception as e:
        logging.error(f"Error copying {original_file} to {config_file}: {e}")
        return False


def handle_config_files(configfiles_conf_path, force=False):
    """
    Process configfiles.conf and handle file overwrites
    
    Args:
        configfiles_conf_path: Path to configfiles.conf file
        force: If True, skip confirmation prompts
        
    Returns:
        Number of successfully processed config files
    """
    config_mappings = read_config_file(configfiles_conf_path)
    if not config_mappings:
        logging.warning("No config file mappings found in configfiles.conf")
        return 0
    
    logging.info(f"Processing {len(config_mappings)} config file mappings from {configfiles_conf_path}")
    
    success_count = 0
    for mapping in config_mappings:
        if ':' not in mapping:
            logging.warning(f"Invalid mapping format: {mapping} (expected 'configfile:original')")
            continue
        
        config_file, original_file = mapping.split(':', 1)
        config_file = config_file.strip()
        original_file = original_file.strip()
        
        if not config_file or not original_file:
            logging.warning(f"Invalid mapping: {mapping}")
            continue
        
        if not os.path.exists(original_file):
            logging.error(f"Original file not found: {original_file}")
            continue
        
        if confirm_overwrite(config_file, original_file, force):
            if copy_config_file(config_file, original_file):
                success_count += 1
        else:
            logging.info(f"Skipped overwriting {config_file}")
    
    logging.info(f"Successfully processed {success_count}/{len(config_mappings)} config files")
    return success_count


def run_config_configtxt_default():
    """
    Run config-configtxt --default command
    
    Returns:
        True if successful, False otherwise
    """
    try:
        logging.info("Running config-configtxt --default")
        result = subprocess.run(
            ['config-configtxt', '--default'],
            capture_output=True,
            text=True,
            check=False
        )
        
        if result.returncode != 0:
            logging.error(f"config-configtxt --default failed: {result.stderr.strip()}")
            return False
        
        if result.stdout.strip():
            logging.info(f"config-configtxt output: {result.stdout.strip()}")
        
        logging.info("config-configtxt --default completed successfully")
        return True
        
    except Exception as e:
        logging.error(f"Error running config-configtxt --default: {e}")
        return False


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


def create_uuid_file():
    """
    Create /etc/uuid file with a unique UUID if it doesn't exist
    
    Returns:
        True if successful or file already exists, False otherwise
    """
    uuid_file = "/etc/uuid"
    
    try:
        if os.path.exists(uuid_file):
            logging.info(f"UUID file already exists: {uuid_file}")
            return True
        
        # Generate a new UUID
        system_uuid = str(uuid.uuid4())
        
        # Write UUID to file
        with open(uuid_file, 'w') as f:
            f.write(system_uuid + '\n')
        
        # Set appropriate permissions (readable by all, writable by root)
        os.chmod(uuid_file, 0o644)
        
        logging.info(f"Created UUID file {uuid_file} with UUID: {system_uuid}")
        return True
        
    except Exception as e:
        logging.error(f"Error creating UUID file {uuid_file}: {e}")
        return False


def run_command(command):
    """
    Execute a shell command with proper logging
    
    Args:
        command: Command string to execute
        
    Returns:
        True if successful, False otherwise
    """
    try:
        logging.info(f"Executing command: {command}")
        result = subprocess.run(
            command,
            shell=True,
            capture_output=True,
            text=True,
            check=False
        )
        
        if result.returncode != 0:
            logging.error(f"Command failed with exit code {result.returncode}: {command}")
            if result.stderr.strip():
                logging.error(f"Error output: {result.stderr.strip()}")
            return False
        
        if result.stdout.strip():
            logging.info(f"Command output: {result.stdout.strip()}")
        
        logging.info(f"Command completed successfully: {command}")
        return True
        
    except Exception as e:
        logging.error(f"Error executing command '{command}': {e}")
        return False


def handle_commands(commands_conf_path):
    """
    Process command.conf and execute all listed commands
    
    Args:
        commands_conf_path: Path to command.conf file
        
    Returns:
        Number of successfully executed commands
    """
    commands = read_config_file(commands_conf_path)
    if not commands:
        logging.warning("No commands found in command.conf")
        return 0
    
    logging.info(f"Processing {len(commands)} commands from {commands_conf_path}")
    
    success_count = 0
    for command in commands:
        if run_command(command):
            success_count += 1
        else:
            logging.warning(f"Command failed, continuing with remaining commands")
    
    logging.info(f"Successfully executed {success_count}/{len(commands)} commands")
    return success_count


def main():
    """Main function"""
    parser = argparse.ArgumentParser(
        description='HiFiBerry base configuration management script'
    )
    
    parser.add_argument(
        '--services-conf',
        default='/etc/hifiberry/baseconfig/services.conf',
        help='Path to services.conf file (default: /etc/hifiberry/baseconfig/services.conf)'
    )
    
    parser.add_argument(
        '--configfiles-conf',
        default='/etc/hifiberry/baseconfig/configfiles.conf',
        help='Path to configfiles.conf file (default: /etc/hifiberry/baseconfig/configfiles.conf)'
    )
    
    parser.add_argument(
        '--commands-conf',
        default='/etc/hifiberry/baseconfig/command.conf',
        help='Path to command.conf file (default: /etc/hifiberry/baseconfig/command.conf)'
    )
    
    parser.add_argument(
        '--force',
        action='store_true',
        help='Force overwrite config files without confirmation'
    )
    
    parser.add_argument(
        '--services-only',
        action='store_true',
        help='Only process services, skip config files'
    )
    
    parser.add_argument(
        '--config-files-only',
        action='store_true',
        help='Only process config files, skip services and commands'
    )
    
    parser.add_argument(
        '--commands-only',
        action='store_true',
        help='Only process commands, skip services and config files'
    )
    
    parser.add_argument(
        '-v', '--verbose',
        action='store_true',
        help='Enable verbose output'
    )
    
    args = parser.parse_args()
    
    # Setup logging
    setup_logging(args.verbose)
    
    # Check if running as root (required for all operations)
    if not check_root_privileges():
        return 1
    
    success = True
    
    # Create UUID file first
    logging.info("=== Creating System UUID ===")
    if not create_uuid_file():
        logging.warning("UUID file creation failed, continuing with other operations")
        success = False
    
    # Run config-configtxt --default first
    logging.info("=== Applying Default Config.txt Settings ===")
    if not run_config_configtxt_default():
        logging.warning("config-configtxt --default failed, continuing with other operations")
        success = False
    
    # Handle services
    if not args.config_files_only and not args.commands_only:
        logging.info("=== Processing Services ===")
        services_processed = handle_services(args.services_conf)
        if services_processed == 0:
            success = False
    
    # Handle config files
    if not args.services_only and not args.commands_only:
        logging.info("=== Processing Config Files ===")
        configs_processed = handle_config_files(args.configfiles_conf, args.force)
        if configs_processed == 0:
            success = False
    
    # Handle commands
    if not args.services_only and not args.config_files_only:
        logging.info("=== Processing Commands ===")
        commands_processed = handle_commands(args.commands_conf)
        if commands_processed == 0:
            success = False
    
    # Create /etc/uuid file
    logging.info("=== Creating /etc/uuid File ===")
    if not create_uuid_file():
        success = False
    
    if success:
        logging.info("Base configuration completed successfully")
        return 0
    else:
        logging.error("Base configuration completed with errors")
        return 1


if __name__ == "__main__":
    sys.exit(main())
