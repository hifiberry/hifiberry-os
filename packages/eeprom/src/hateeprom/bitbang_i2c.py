#!/usr/bin/env python3
"""
Bitbang I2C implementation using libgpiod.
"""

import time
import gpiod


class I2CClient:
    """
    Bitbang I2C client implementation using libgpiod.
    """
    
    def __init__(self, sda_pin: int = 0, scl_pin: int = 1, frequency: float = 50000, chip_name: str = "/dev/gpiochip0"):
        """
        Initialize the I2C client.
        
        Args:
            sda_pin (int): GPIO pin number for SDA (data line). Default: 0
            scl_pin (int): GPIO pin number for SCL (clock line). Default: 1
            frequency (float): I2C frequency in Hz. Default: 50kHz
            chip_name (str): GPIO chip device path. Default: "/dev/gpiochip0"
        """
        self.sda_pin = sda_pin
        self.scl_pin = scl_pin
        self.frequency = frequency
        self.chip_name = chip_name
        
        # Calculate timing based on frequency
        self.half_period = 1.0 / (2 * frequency)  # Half period delay

        
        # make sure both lines are H
        self.sda_state = True
        self.scl_state = True
        sda_settings = self._sda_settings(high=True)
        scl_settings = self._scl_settings(high=True)
        line_config = {self.sda_pin: sda_settings, self.scl_pin: scl_settings}
        self.chip = gpiod.Chip(self.chip_name)
        self.request = self.chip.request_lines(consumer="i2c_client", config=line_config)       
    
    def _delay(self):
        """Delay for half period based on frequency."""
        time.sleep(self.half_period)
    
    def _sda_settings(self, high=False):
        """Create SDA line settings based on desired state.
        high=True: Input (released, pulled high by external resistor)
        high=False: Output driving low
        """
        if high:
            return gpiod.LineSettings(direction=gpiod.line.Direction.INPUT)
        else:
            return gpiod.LineSettings(
                direction=gpiod.line.Direction.OUTPUT,
                output_value=gpiod.line.Value.INACTIVE
            )
    
    def _scl_settings(self, high=False):
        """Create SCL line settings based on desired state.
        high=True: Input (released, pulled high by external resistor)
        high=False: Output driving low
        """
        if high:
            return gpiod.LineSettings(direction=gpiod.line.Direction.INPUT)
        else:
            return gpiod.LineSettings(
                direction=gpiod.line.Direction.OUTPUT,
                output_value=gpiod.line.Value.INACTIVE
            )
    
    def sda_h(self, force=False):
        """Set SDA high by configuring as input (open-drain behavior)."""
        # Release current request and recreate with SDA as input

        if not force and self.sda_state:
            return # already high, no change needed

        self.request.release()
        
        sda_settings = self._sda_settings(high=True)
        scl_settings = self._scl_settings(high=self.scl_state)
        
        line_config = {self.sda_pin: sda_settings, self.scl_pin: scl_settings}
        self.request = self.chip.request_lines(consumer="i2c_client", config=line_config)
        self.sda_state = True
    
    def sda_l(self, force=False):
        """Set SDA low by actively driving low."""
        if not force and not self.sda_state:
            return # Only reconfigure if not already low

        self.request.release()
        
        sda_settings = self._sda_settings(high=False)
        scl_settings = self._scl_settings(high=self.scl_state)
        
        line_config = {self.sda_pin: sda_settings, self.scl_pin: scl_settings}
        self.request = self.chip.request_lines(consumer="i2c_client", config=line_config)
        
        self.sda_state = False
    
    def scl_h(self, force=False):
        """Set SCL high by configuring as input (open-drain behavior)."""
        # Release current request and recreate with SCL as input

        if not force and self.scl_state:
            return # already high, no change needed

        self.request.release()
        
        sda_settings = self._sda_settings(high=self.sda_state)
        scl_settings = self._scl_settings(high=True)
        
        line_config = {self.sda_pin: sda_settings, self.scl_pin: scl_settings}
        self.request = self.chip.request_lines(consumer="i2c_client", config=line_config)
        self.scl_state = True
    
    def scl_l(self, force=False):
        """Set SCL low by actively driving low."""
        # Release current request and recreate with SCL as output low

        if not force and not self.scl_state:
            return # Only reconfigure if not already low
        
        self.request.release()
        
        sda_settings = self._sda_settings(high=self.sda_state)
        scl_settings = self._scl_settings(high=False)
        
        line_config = {self.sda_pin: sda_settings, self.scl_pin: scl_settings}
        self.request = self.chip.request_lines(consumer="i2c_client", config=line_config)
        self.scl_state = False
    
    def i2c_start(self):
        """Generate I2C START condition: pull down SDA first, then SCL."""
        # Ensure both lines are initially high (idle state)
        self.sda_h()
        self.scl_h()
        self._delay()
        
        # START condition: SDA goes low while SCL is high
        self.sda_l()
        self._delay()
        
        # Then pull SCL low
        self.scl_l()
        self._delay()
    
    def i2c_stop(self):
        """Generate I2C STOP condition: pull up SCL first, then SDA."""
        # Ensure SDA is low initially
        self.sda_l()
        self._delay()
        
        # STOP condition: SCL goes high first
        self.scl_h()
        self._delay()
        
        # Then SDA goes high while SCL is high
        self.sda_h()
        self._delay()
    
    def write_byte(self, byte_data: int) -> bool:
        """
        Write a byte to I2C bus and read ACK.
        
        Args:
            byte_data (int): Byte to write (0-255)
            
        Returns:
            bool: True if ACK received (SDA=0), False if NACK (SDA=1)
        """
        # Ensure SDA is configured as output
        self.sda_l()
        self.scl_l()
        
        # Write 8 bits, MSB first
        for i in range(7, -1, -1):
            bit = (byte_data >> i) & 1

            # Set clock low
            self.scl_l()
            self._delay()
            
            # Write bit to SDA
            if bit:
                self.sda_h()
            else:
                self.sda_l()
            self._delay()
            
            # Set clock high
            self.scl_h()
            self._delay()
        
        # After 8 bits, read ACK
        self.scl_l()
        
        # Configure SDA as input to read ACK
        self.sda_h()
        self._delay()
        
        # Clock high to read ACK
        self.scl_h()
        self._delay()
        
        # Read SDA (should be 0 for ACK)
        values = self.request.get_values([self.sda_pin])
        ack_bit = 1 if values[0] == gpiod.line.Value.ACTIVE else 0
        
        # Clock low to complete ACK cycle
        self.scl_l()
        self._delay()
        
        return ack_bit == 0  # True if ACK (0), False if NACK (1)
    
    def read_byte(self, send_ack=True):
        """
        Read a byte from I2C bus and send ACK/NACK to slave.
        
        Args:
            send_ack (bool): True to send ACK (continue reading), False to send NACK (stop reading)
            
        Returns:
            int: Received byte (0-255)
        """
        # Configure SDA as input for reading
        self.sda_h()
        
        byte_data = 0
        
        # Read 8 bits, MSB first
        for i in range(8):
            # Set clock low
            self.scl_l()
            self._delay()
            
            # Set clock high and read bit
            self.scl_h()
            self._delay()
            
            # Read SDA line
            values = self.request.get_values([self.sda_pin])
            bit = 1 if values[0] == gpiod.line.Value.ACTIVE else 0
            
            # Shift and add bit to byte
            byte_data = (byte_data << 1) | bit
        
        # After 8 bits, master sends ACK/NACK to slave
        self._delay()
        self.scl_l()
        
        # Send ACK (0) or NACK (1)
        if send_ack:
            self.sda_l()  # ACK = low (master wants more data)
        else:
            self.sda_h()  # NACK = high (master is done reading)
        self._delay()
        
        # Clock the ACK/NACK
        self.scl_h()
        self._delay()
        self.scl_l()
        self._delay()
        
        return byte_data
    
    def write_bytes(self, byte_list: list) -> bool:
        """
        Write multiple bytes to I2C bus.
        
        Args:
            byte_list (list): List of bytes to write (each 0-255)
            
        Returns:
            bool: True if all bytes were ACKed, False if any NACK occurred
        """
        for i, byte_data in enumerate(byte_list):
            ack = self.write_byte(byte_data)
            if not ack:
                print(f"NACK received at byte {i} (0x{byte_data:02X})")
                return False
        return True
    
    def write_reg(self, addr, reg, value):
        """
        Write a value to a specific register of an I2C device.
        
        Args:
            addr (int): I2C device address (7-bit, without read/write bit)
            reg (int): Register address to write to (0-255)
            value (int): Value to write to the register (0-255)
            
        Returns:
            bool: True if successful, False if any NACK occurred
        """
        try:
            # Start I2C transaction
            self.i2c_start()
            
            # Write device address with write bit (addr << 1 | 0)
            device_addr = (addr << 1) | 0  # Write bit = 0
            ack1 = self.write_byte(device_addr)
            if not ack1:
                print(f"Device address 0x{addr:02X} did not ACK")
                self.i2c_stop()
                return False
            
            # Write register address
            ack2 = self.write_byte(reg)
            if not ack2:
                print(f"Register address 0x{reg:02X} did not ACK")
                self.i2c_stop()
                return False
            
            # Write value to register
            ack3 = self.write_byte(value)
            if not ack3:
                print(f"Register value 0x{value:02X} did not ACK")
                self.i2c_stop()
                return False
            
            # Stop I2C transaction
            self.i2c_stop()
            return True
            
        except Exception as e:
            print(f"Error in write_reg: {e}")
            self.i2c_stop()  # Ensure bus is released
            return False
    
    def cleanup(self):
        """Clean up GPIO resources."""
        try:
            if self.request:
                # Set both pins high before cleanup
                self.sda_h()
                self.scl_h()
                self.request.release()
                self.request = None
            
            if self.chip:
                self.chip.close()
                self.chip = None
            
            print("GPIO cleanup completed.")
            
        except Exception as e:
            print(f"Cleanup error: {e}")
    
    def __enter__(self):
        """Context manager entry."""
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit."""
        self.cleanup()

    def read_eeprom(self, device_addr: int, start_addr: int, length: int) -> list:
        """
        Read data from EEPROM at specified address.
        
        Args:
            device_addr (int): I2C device address (7-bit, e.g., 0x50 for EEPROM)
            start_addr (int): Starting memory address to read from (0-65535 for 16-bit addressing)
            length (int): Number of bytes to read
            
        Returns:
            list: List of bytes read from EEPROM
            
        Raises:
            RuntimeError: If any I2C operation fails (NACK received)
            
        Note:
            Uses 16-bit addressing suitable for 24LC256P and similar EEPROMs.
        """
        try:
            # Start I2C transaction
            self.i2c_start()
            
            # Write device address with write bit to set read pointer
            write_addr = (device_addr << 1) | 0  # Write bit = 0
            # write_addr sent
            if not self.write_byte(write_addr):
                raise RuntimeError(f"Device address 0x{device_addr:02X} did not ACK (write)")
            
            # Write memory address (16-bit addressing for 24LC256P)
            # Send high byte first, then low byte
            addr_high = (start_addr >> 8) & 0xFF
            addr_low = start_addr & 0xFF
            
            # mem addr high sent
            if not self.write_byte(addr_high):
                raise RuntimeError(f"Memory address high byte 0x{addr_high:02X} did not ACK")
                
            # mem addr low sent
            if not self.write_byte(addr_low):
                raise RuntimeError(f"Memory address low byte 0x{addr_low:02X} did not ACK")
            
            # Repeated start for read operation
            self.i2c_start()
            
            # Write device address with read bit
            read_addr = (device_addr << 1) | 1  # Read bit = 1
            # read_addr sent
            if not self.write_byte(read_addr):
                raise RuntimeError(f"Device address 0x{device_addr:02X} did not ACK (read)")
            
            # Read the requested number of bytes
            data = []
            for i in range(length):
                # Send ACK for all bytes except the last one
                send_ack = (i < length - 1)
                byte_data = self.read_byte(send_ack=send_ack)
                data.append(byte_data)
            
            # Stop I2C transaction
            self.i2c_stop()
            
            return data
            
        except Exception as e:
            # Ensure bus is released on error
            self.i2c_stop()
            raise RuntimeError(f"EEPROM read failed: {e}")

    def read_eeprom_byte(self, i2c_addr: int, address: int) -> tuple[int, bool]:
        """
        Read a single byte from EEPROM (compatibility method for HatEEPROM).
        
        Args:
            i2c_addr (int): I2C device address (7-bit)
            address (int): Memory address to read from
            
        Returns:
            tuple: (value, success) - value is the byte read, success is True/False
        """
        try:
            data = self.read_eeprom(i2c_addr, address, 1)
            return data[0], True
        except Exception:
            return 0, False

    def write_eeprom_byte(self, i2c_addr: int, address: int, value: int) -> bool:
        """
        Write a single byte to EEPROM (compatibility method for HatEEPROM).
        
        Args:
            i2c_addr (int): I2C device address (7-bit)
            address (int): Memory address to write to
            value (int): Byte value to write
            
        Returns:
            bool: True if successful, False if failed
        """
        try:
            # Start I2C transaction
            self.i2c_start()
            
            # Write device address with write bit
            write_addr = (i2c_addr << 1) | 0  # Write bit = 0
            if not self.write_byte(write_addr):
                raise RuntimeError(f"Device address 0x{i2c_addr:02X} did not ACK")
            
            # Write memory address (16-bit addressing)
            addr_high = (address >> 8) & 0xFF
            addr_low = address & 0xFF
            
            if not self.write_byte(addr_high):
                raise RuntimeError(f"Memory address high byte 0x{addr_high:02X} did not ACK")
                
            if not self.write_byte(addr_low):
                raise RuntimeError(f"Memory address low byte 0x{addr_low:02X} did not ACK")
            
            # Write data byte
            if not self.write_byte(value):
                raise RuntimeError(f"Data byte 0x{value:02X} did not ACK")
            
            # Stop I2C transaction
            self.i2c_stop()
            return True
            
        except Exception:
            self.i2c_stop()
            return False

    def read_eeprom_sequential(self, i2c_addr: int, address: int, length: int) -> tuple[bytes, bool]:
        """
        Read multiple bytes sequentially from EEPROM (compatibility method for HatEEPROM).
        
        Args:
            i2c_addr (int): I2C device address (7-bit)
            address (int): Starting memory address
            length (int): Number of bytes to read
            
        Returns:
            tuple: (data, success) - data is bytes object, success is True/False
        """
        try:
            data_list = self.read_eeprom(i2c_addr, address, length)
            return bytes(data_list), True
        except Exception:
            return bytes(), False


if __name__ == "__main__":
    import argparse
    import sys
    
    parser = argparse.ArgumentParser(description='I2C EEPROM Tool using bitbang I2C')
    parser.add_argument('--sda', type=int, default=0, help='SDA GPIO pin number (default: 0)')
    parser.add_argument('--scl', type=int, default=1, help='SCL GPIO pin number (default: 1)')
    parser.add_argument('--freq', type=float, default=50000, help='I2C frequency in Hz (default: 50000)')
    parser.add_argument('--chip', default='/dev/gpiochip0', help='GPIO chip device (default: /dev/gpiochip0)')
    
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # Read EEPROM command
    read_parser = subparsers.add_parser('read', help='Read data from EEPROM')
    read_parser.add_argument('device_addr', type=lambda x: int(x, 0), help='I2C device address (7-bit, e.g., 0x50)')
    read_parser.add_argument('start_addr', type=lambda x: int(x, 0), help='Starting memory address (e.g., 0x0000)')
    read_parser.add_argument('length', type=int, help='Number of bytes to read')
    read_parser.add_argument('--output', '-o', help='Output file (optional)')
    read_parser.add_argument('--format', choices=['hex', 'binary'], default='hex', 
                           help='Output format: hex dump or binary data (default: hex)')
    
    # Write register command
    write_parser = subparsers.add_parser('write-reg', help='Write to I2C register')
    write_parser.add_argument('device_addr', type=lambda x: int(x, 0), help='I2C device address (7-bit)')
    write_parser.add_argument('register', type=lambda x: int(x, 0), help='Register address')
    write_parser.add_argument('value', type=lambda x: int(x, 0), help='Value to write')
    
    # Write EEPROM byte command
    write_eeprom_parser = subparsers.add_parser('write-byte', help='Write single byte to EEPROM')
    write_eeprom_parser.add_argument('device_addr', type=lambda x: int(x, 0), help='I2C device address (7-bit)')
    write_eeprom_parser.add_argument('address', type=lambda x: int(x, 0), help='Memory address')
    write_eeprom_parser.add_argument('value', type=lambda x: int(x, 0), help='Byte value to write')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        sys.exit(1)
    
    try:
        # Initialize I2C client
        with I2CClient(sda_pin=args.sda, scl_pin=args.scl, frequency=args.freq, chip_name=args.chip) as i2c:
            
            if args.command == 'read':
                print(f"Reading {args.length} bytes from device 0x{args.device_addr:02X} at address 0x{args.start_addr:04X}")
                
                # Read data from EEPROM
                data = i2c.read_eeprom(args.device_addr, args.start_addr, args.length)
                
                if args.output:
                    # Write to file
                    if args.format == 'binary':
                        with open(args.output, 'wb') as f:
                            f.write(bytes(data))
                        print(f"Binary data written to {args.output}")
                    else:
                        with open(args.output, 'w') as f:
                            for i in range(0, len(data), 16):
                                line = data[i:i+16]
                                ascii_line = ''.join(chr(b) if 32 <= b <= 126 else '.' for b in line)
                                hex_line = ' '.join(f"{b:02X}" for b in line)
                                f.write(f"{args.start_addr + i:04X}: {hex_line:<48} {ascii_line}\n")
                        print(f"Hex dump written to {args.output}")
                else:
                    # Print to console
                    if args.format == 'binary':
                        sys.stdout.buffer.write(bytes(data))
                    else:
                        for i in range(0, len(data), 16):
                            line = data[i:i+16]
                            ascii_line = ''.join(chr(b) if 32 <= b <= 126 else '.' for b in line)
                            hex_line = ' '.join(f"{b:02X}" for b in line)
                            print(f"{args.start_addr + i:04X}: {hex_line:<48} {ascii_line}")
                
                print(f"Successfully read {len(data)} bytes")
            
            elif args.command == 'write-reg':
                print(f"Writing 0x{args.value:02X} to register 0x{args.register:02X} on device 0x{args.device_addr:02X}")
                
                success = i2c.write_reg(args.device_addr, args.register, args.value)
                
                if success:
                    print("Write successful")
                else:
                    print("Write failed")
                    sys.exit(1)
            
            elif args.command == 'write-byte':
                print(f"Writing 0x{args.value:02X} to EEPROM address 0x{args.address:04X} on device 0x{args.device_addr:02X}")
                
                success = i2c.write_eeprom_byte(args.device_addr, args.address, args.value)
                
                if success:
                    print("Write successful")
                else:
                    print("Write failed")
                    sys.exit(1)
                
    except KeyboardInterrupt:
        print("\nOperation cancelled by user")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)