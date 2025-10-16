#!/usr/bin/env python3
"""
Bitbanging I2C implementation using libgpiod 2.x
"""

import time
from typing import Optional

try:
    import gpiod
except ImportError:
    raise ImportError("python3-libgpiod is required. Install with: sudo apt install python3-libgpiod")


class BitbangI2C:
    """Bitbanging I2C implementation using libgpiod 2.x API only"""
    
    def __init__(self, chip_name: str = "gpiochip0", sda_pin: int = 0, scl_pin: int = 1, delay: float = 0.000020):
        """
        Initialize I2C bitbang interface
        
        Args:
            chip_name: GPIO chip name (default: gpiochip0)
            sda_pin: SDA pin number (default: 0 - GPIO0)
            scl_pin: SCL pin number (default: 1 - GPIO1)  
            delay: Bit delay in seconds (default: 20us)
        """
        self.sda_pin = sda_pin
        self.scl_pin = scl_pin
        self.delay = delay
        
        try:
            # Handle both chip name and full device path
            if chip_name.startswith('/dev/'):
                chip_path = chip_name
            else:
                chip_path = f"/dev/{chip_name}"
            
            self.chip = gpiod.Chip(chip_path)
            
            # Initialize both pins as outputs, starting high (idle state)
            output_settings = gpiod.LineSettings(
                direction=gpiod.line.Direction.OUTPUT,
                output_value=gpiod.line.Value.ACTIVE
            )
            
            output_config = {
                self.sda_pin: output_settings,
                self.scl_pin: output_settings
            }
            
            self.line_request = self.chip.request_lines(
                consumer="hateeprom",
                config=output_config
            )
                
        except Exception as e:
            raise IOError(f"Error initializing GPIO: {e}")
    
    def __del__(self):
        """Cleanup GPIO resources"""
        try:
            if hasattr(self, 'line_request'):
                self.line_request.release()
            if hasattr(self, 'chip'):
                self.chip.close()
        except:
            pass
    
    def _delay(self):
        """Delay for I2C timing"""
        time.sleep(self.delay)
    
    def clk_h(self):
        """Set SCL (clock) high"""
        self.line_request.set_value(self.scl_pin, gpiod.line.Value.ACTIVE)
        self._delay()
    
    def clk_low(self):
        """Set SCL (clock) low"""
        self.line_request.set_value(self.scl_pin, gpiod.line.Value.INACTIVE)
        self._delay()
    
    def data_h(self):
        """Set SDA (data) high"""
        self.line_request.set_value(self.sda_pin, gpiod.line.Value.ACTIVE)
        self._delay()
    
    def data_low(self):
        """Set SDA (data) low"""
        self.line_request.set_value(self.sda_pin, gpiod.line.Value.INACTIVE)
        self._delay()
    
    def data_as_input(self):
        """Configure SDA as input to allow slave to drive it"""
        # Release current request
        self.line_request.release()
        
        # Create new configuration with SDA as input, SCL as output
        input_settings = gpiod.LineSettings(direction=gpiod.line.Direction.INPUT)
        output_settings = gpiod.LineSettings(
            direction=gpiod.line.Direction.OUTPUT,
            output_value=gpiod.line.Value.ACTIVE
        )
        
        config = {
            self.sda_pin: input_settings,
            self.scl_pin: output_settings
        }
        
        self.line_request = self.chip.request_lines(
            consumer="hateeprom",
            config=config
        )
    
    def data_as_output(self):
        """Configure SDA as output for master to drive it"""
        # Release current request
        self.line_request.release()
        
        # Create new configuration with both as outputs
        output_settings = gpiod.LineSettings(
            direction=gpiod.line.Direction.OUTPUT,
            output_value=gpiod.line.Value.ACTIVE
        )
        
        config = {
            self.sda_pin: output_settings,
            self.scl_pin: output_settings
        }
        
        self.line_request = self.chip.request_lines(
            consumer="hateeprom",
            config=config
        )
    
    def read_sda(self) -> bool:
        """Read SDA pin state (assumes SDA is configured as input)"""
        return self.line_request.get_value(self.sda_pin) == gpiod.line.Value.ACTIVE

    def i2c_start(self):
        """Generate I2C start condition"""
        self.data_as_output()
        self.data_low()
        self._delay()
        self.clk_low()

    def i2c_stop(self):
        """Generate I2C stop condition"""
        self.clk_h()
        self._delay()
        self.data_as_input()

    def write_bit(self, bit: bool):
        """Write a single bit"""
        if bit:
            self.data_h()
        else:
            self.data_low()
        self._delay()
        self.clk_h()
        self._delay()
        self.clk_low()

    def read_bit(self) -> bool:
        """Read a single bit"""
        self._delay()
        self.clk_h()
        bit = self.read_sda()
        self._delay()
        self.clk_low()
        return bit

    def write_byte(self, byte: int) -> bool:
        """Write a byte from MSB to LSB and return ACK status"""
        # Write 8 bits from MSB to LSB
        for i in range(7, -1, -1):
            bit = (byte >> i) & 1
            self.write_bit(bool(bit))
        
        # After 8 bits, read ACK/NACK
        self.data_as_input()
        self._delay()
        self.clk_h()
        ack_bit = self.read_sda()
        self.clk_low()
        
        # If bit=0, ACK (ok), otherwise NACK (not ok)
        return ack_bit == False  # ACK is low (0), NACK is high (1)

    def read_byte(self) -> tuple[int, bool]:
        """Read a byte from MSB to LSB and read ACK/NACK from slave"""
        # Configure SDA as input
        self.data_as_input()
        
        # Read 8 bits from MSB to LSB
        byte = 0
        for i in range(8):
            bit = self.read_bit()
            byte = (byte << 1) | (1 if bit else 0)
        
        # Read ACK/NACK from slave (9th bit)
        self._delay()
        self.clk_h()
        ack_bit = self.read_sda()
        self.clk_low()
        
        # If bit=0, ACK (ok), otherwise NACK (not ok)
        ack_received = ack_bit == False  # ACK is low (0), NACK is high (1)
        
        return byte, ack_received

    def write_bytes(self, data: list, with_start_stop: bool = True) -> bool:
        """Write multiple bytes with optional start/stop conditions"""
        if with_start_stop:
            self.i2c_start()
        
        # Write each byte and check for ACK
        for byte in data:
            if not self.write_byte(byte):
                # NACK received, stop transmission
                if with_start_stop:
                    self.i2c_stop()
                return False
        
        if with_start_stop:
            self.i2c_stop()
        
        return True

    def write_register(self, i2c_addr: int, reg: int, value: int) -> bool:
        """Write a value to a register"""
        return self.write_bytes([i2c_addr, reg, value])

    def read_register(self, i2c_addr: int, reg: int) -> tuple[int, bool]:
        """Read a value from a register"""
        self.i2c_start()
        
        # Write I2C address + write bit (0)
        if not self.write_byte(i2c_addr & 0xFE):  # Clear LSB for write
            self.i2c_stop()
            return 0, False
        
        # Write register address
        if not self.write_byte(reg):
            self.i2c_stop()
            return 0, False
        
        # Repeated start for read
        self.i2c_start()
        
        # Write I2C address + read bit (1)
        if not self.write_byte(i2c_addr | 0x01):  # Set LSB for read
            self.i2c_stop()
            return 0, False
        
        # Read the value
        value, ack = self.read_byte()
        
        self.i2c_stop()
        
        return value, ack


def main():
    """Command line interface for I2C register operations"""
    import argparse
    import sys
    
    parser = argparse.ArgumentParser(description='I2C Register Tool using BitbangI2C')
    parser.add_argument('--chip', default='gpiochip0', help='GPIO chip (default: gpiochip0)')
    parser.add_argument('--sda', type=int, default=0, help='SDA pin number (default: 0)')
    parser.add_argument('--scl', type=int, default=1, help='SCL pin number (default: 1)')
    parser.add_argument('--delay', type=float, default=0.000020, help='Bit delay in seconds (default: 20us)')
    
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # Write register command
    write_parser = subparsers.add_parser('write', help='Write to a register')
    write_parser.add_argument('address', type=lambda x: int(x, 0), help='I2C device address (hex or decimal)')
    write_parser.add_argument('register', type=lambda x: int(x, 0), help='Register address (hex or decimal)')
    write_parser.add_argument('value', type=lambda x: int(x, 0), help='Value to write (hex or decimal)')
    
    # Read register command
    read_parser = subparsers.add_parser('read', help='Read from a register')
    read_parser.add_argument('address', type=lambda x: int(x, 0), help='I2C device address (hex or decimal)')
    read_parser.add_argument('register', type=lambda x: int(x, 0), help='Register address (hex or decimal)')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        sys.exit(1)
    
    try:
        # Initialize I2C
        i2c = BitbangI2C(chip_name=args.chip, sda_pin=args.sda, scl_pin=args.scl, delay=args.delay)
        
        if args.command == 'write':
            print(f"Writing 0x{args.value:02X} to register 0x{args.register:02X} on device 0x{args.address:02X}")
            success = i2c.write_register(args.address, args.register, args.value)
            if success:
                print("Write successful (ACK received)")
                sys.exit(0)
            else:
                print("Write failed (NACK received)")
                sys.exit(1)
        
        elif args.command == 'read':
            print(f"Reading from register 0x{args.register:02X} on device 0x{args.address:02X}")
            value, ack = i2c.read_register(args.address, args.register)
            if ack:
                print(f"Read successful: 0x{value:02X} ({value})")
                sys.exit(0)
            else:
                print(f"Read completed but got NACK: 0x{value:02X} ({value})")
                sys.exit(1)
    
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()

    def i2c_start(self):
        """Generate I2C start condition"""
        self.data_as_output()
        self.data_low()
        self._delay()
        self.clk_low()

    def i2c_stop(self):
        """Generate I2C stop condition"""
        self.clk_h()
        self._delay()
        self.data_as_input()

    def write_bit(self, bit: bool):
        """Write a single bit"""
        if bit:
            self.data_h()
        else:
            self.data_low()
        self._delay()
        self.clk_h()
        self._delay()
        self.clk_low()

    def read_bit(self) -> bool:
        """Read a single bit"""
        self._delay()
        self.clk_h()
        bit = self.read_sda()
        self._delay()
        self.clk_low()
        return bit

    def write_byte(self, byte: int) -> bool:
        """Write a byte from MSB to LSB and return ACK status"""
        # Write 8 bits from MSB to LSB
        for i in range(7, -1, -1):
            bit = (byte >> i) & 1
            self.write_bit(bool(bit))
        
        # After 8 bits, read ACK/NACK
        self.data_as_input()
        self._delay()
        self.clk_h()
        ack_bit = self.read_sda()
        self.clk_low()
        
        # If bit=0, ACK (ok), otherwise NACK (not ok)
        return ack_bit == False  # ACK is low (0), NACK is high (1)

    def read_byte(self) -> tuple[int, bool]:
        """Read a byte from MSB to LSB and read ACK/NACK from slave"""
        # Configure SDA as input
        self.data_as_input()
        
        # Read 8 bits from MSB to LSB
        byte = 0
        for i in range(8):
            bit = self.read_bit()
            byte = (byte << 1) | (1 if bit else 0)
        
        # Read ACK/NACK from slave (9th bit)
        self._delay()
        self.clk_h()
        ack_bit = self.read_sda()
        self.clk_low()
        
        # If bit=0, ACK (ok), otherwise NACK (not ok)
        ack_received = ack_bit == False  # ACK is low (0), NACK is high (1)
        
        return byte, ack_received

    def write_bytes(self, data: list, with_start_stop: bool = True) -> bool:
        """Write multiple bytes with optional start/stop conditions"""
        if with_start_stop:
            self.i2c_start()
        
        # Write each byte and check for ACK
        for byte in data:
            if not self.write_byte(byte):
                # NACK received, stop transmission
                if with_start_stop:
                    self.i2c_stop()
                return False
        
        if with_start_stop:
            self.i2c_stop()
        
        return True

    def write_register(self, i2c_addr: int, reg: int, value: int) -> bool:
        """Write a value to a register"""
        return self.write_bytes([i2c_addr, reg, value])

    def read_register(self, i2c_addr: int, reg: int) -> tuple[int, bool]:
        """Read a value from a register"""
        self.i2c_start()
        
        # Write I2C address + write bit (0)
        if not self.write_byte(i2c_addr & 0xFE):  # Clear LSB for write
            self.i2c_stop()
            return 0, False
        
        # Write register address
        if not self.write_byte(reg):
            self.i2c_stop()
            return 0, False
        
        # Repeated start for read
        self.i2c_start()
        
        # Write I2C address + read bit (1)
        if not self.write_byte(i2c_addr | 0x01):  # Set LSB for read
            self.i2c_stop()
            return 0, False
        
        # Read the value
        value, ack = self.read_byte()
        
        self.i2c_stop()
        
        return value, ack

    def i2c_start(self):
        """Generate I2C start condition"""
        self.data_as_output()
        self.data_low()
        self._delay()
        self.clk_low()

    def i2c_stop(self):
        """Generate I2C stop condition"""
        self.clk_h()
        self._delay()
        self.data_as_input()

    def write_bit(self, bit: bool):
        """Write a single bit"""
        if bit:
            self.data_h()
        else:
            self.data_low()
        self._delay()
        self.clk_h()
        self._delay()
        self.clk_low()

    def read_bit(self) -> bool:
        """Read a single bit"""
        self._delay()
        self.clk_h()
        bit = self.read_sda()
        self._delay()
        self.clk_low()
        return bit

    def write_byte(self, byte: int) -> bool:
        """Write a byte from MSB to LSB and return ACK status"""
        # Write 8 bits from MSB to LSB
        for i in range(7, -1, -1):
            bit = (byte >> i) & 1
            self.write_bit(bool(bit))
        
        # After 8 bits, read ACK/NACK
        self.data_as_input()
        self._delay()
        self.clk_h()
        ack_bit = self.read_sda()
        self.clk_low()
        
        # If bit=0, ACK (ok), otherwise NACK (not ok)
        return ack_bit == False  # ACK is low (0), NACK is high (1)

    def read_byte(self) -> tuple[int, bool]:
        """Read a byte from MSB to LSB and read ACK/NACK from slave"""
        # Configure SDA as input
        self.data_as_input()
        
        # Read 8 bits from MSB to LSB
        byte = 0
        for i in range(8):
            bit = self.read_bit()
            byte = (byte << 1) | (1 if bit else 0)
        
        # Read ACK/NACK from slave (9th bit)
        self._delay()
        self.clk_h()
        ack_bit = self.read_sda()
        self.clk_low()
        
        # If bit=0, ACK (ok), otherwise NACK (not ok)
        ack_received = ack_bit == False  # ACK is low (0), NACK is high (1)
        
        return byte, ack_received

    def write_bytes(self, data: list, with_start_stop: bool = True) -> bool:
        """Write multiple bytes with optional start/stop conditions"""
        if with_start_stop:
            self.i2c_start()
        
        # Write each byte and check for ACK
        for byte in data:
            if not self.write_byte(byte):
                # NACK received, stop transmission
                if with_start_stop:
                    self.i2c_stop()
                return False
        
        if with_start_stop:
            self.i2c_stop()
        
        return True

    def i2c_start(self):
        """Generate I2C start condition"""
        self.data_as_output()
        self.data_low()
        self._delay()
        self.clk_low()

    def i2c_stop(self):
        """Generate I2C stop condition"""
        self.clk_h()
        self._delay()
        self.data_as_input()

    def write_bit(self, bit: bool):
        """Write a single bit"""
        if bit:
            self.data_h()
        else:
            self.data_low()
        self._delay()
        self.clk_h()
        self._delay()
        self.clk_low()

    def read_bit(self) -> bool:
        """Read a single bit"""
        self._delay()
        self.clk_h()
        bit = self.read_sda()
        self._delay()
        self.clk_low()
        return bit

    def write_byte(self, byte: int) -> bool:
        """Write a byte from MSB to LSB and return ACK status"""
        # Write 8 bits from MSB to LSB
        for i in range(7, -1, -1):
            bit = (byte >> i) & 1
            self.write_bit(bool(bit))
        
        # After 8 bits, read ACK/NACK
        self.data_as_input()
        self._delay()
        self.clk_h()
        ack_bit = self.read_sda()
        self.clk_low()
        
        # If bit=0, ACK (ok), otherwise NACK (not ok)
        return ack_bit == False  # ACK is low (0), NACK is high (1)

    def write_bytes(self, data: list, with_start_stop: bool = True) -> bool:
        """Write multiple bytes with optional start/stop conditions"""
        if with_start_stop:
            self.i2c_start()
        
        # Write each byte and check for ACK
        for byte in data:
            if not self.write_byte(byte):
                # NACK received, stop transmission
                if with_start_stop:
                    self.i2c_stop()
                return False
        
        if with_start_stop:
            self.i2c_stop()
        
        return True

    def i2c_start(self):
        """Generate I2C start condition"""
        self.data_as_output()
        self.data_low()
        self._delay()
        self.clk_low()

    def i2c_stop(self):
        """Generate I2C stop condition"""
        self.clk_h()
        self._delay()
        self.data_as_input()

    def write_bit(self, bit: bool):
        """Write a single bit"""
        if bit:
            self.data_h()
        else:
            self.data_low()
        self._delay()
        self.clk_h()
        self._delay()
        self.clk_low()

    def read_bit(self) -> bool:
        """Read a single bit"""
        self._delay()
        self.clk_h()
        bit = self.read_sda()
        self._delay()
        self.clk_low()
        return bit

    def write_byte(self, byte: int) -> bool:
        """Write a byte from MSB to LSB and return ACK status"""
        # Write 8 bits from MSB to LSB
        for i in range(7, -1, -1):
            bit = (byte >> i) & 1
            self.write_bit(bool(bit))
        
        # After 8 bits, read ACK/NACK
        self.data_as_input()
        self._delay()
        self.clk_h()
        ack_bit = self.read_sda()
        self.clk_low()
        
        # If bit=0, ACK (ok), otherwise NACK (not ok)
        return ack_bit == False  # ACK is low (0), NACK is high (1)

    def i2c_start(self):
        """Generate I2C start condition"""
        self.data_as_output()
        self.data_low()
        self._delay()
        self.clk_low()

    def i2c_stop(self):
        """Generate I2C stop condition"""
        self.clk_h()
        self._delay()
        self.data_as_input()

    def write_bit(self, bit: bool):
        """Write a single bit"""
        if bit:
            self.data_h()
        else:
            self.data_low()
        self._delay()
        self.clk_h()
        self._delay()
        self.clk_low()

    def read_bit(self) -> bool:
        """Read a single bit"""
        self._delay()
        self.clk_h()
        bit = self.read_sda()
        self._delay()
        self.clk_low()
        return bit
