import argparse
import subprocess

# Constants for default offsets
DEFAULT_OFFSETS = [0x35, 0x4E]  # 53 and 78 in decimal

# Updated definitions for inputs and outputs
INPUTS = ["Pi", "AES", "Analog", "Generator"]
OUTPUTS = ["Pi", "AES", "Analog"]

# Dictionary to manage multiple matrices by name
MATRICES = {
    "default": [
        [0, 1, 1, 0],  # AES In and Analog In to Pi
        [1, 0, 0, 0],  # Pi to AES Out
        [1, 0, 0, 0]   # Pi to Analog Out
    ],
    "in_aes": [
        [0, 1, 0, 0],  # AES In to Pi
        [1, 0, 0, 0],  # Pi to AES Out
        [1, 0, 0, 0]   # Pi to Analog Out
    ],
    "in_analog": [
        [0, 0, 1, 0],  # Analog In to Pi
        [1, 0, 0, 0],  # Pi to AES Out
        [1, 0, 0, 0]   # Pi to Analog Out
    ],
    "generator": [
        [0, 0, 0, 1],  # Generator to all outputs
        [0, 0, 0, 1],
        [0, 0, 0, 1]
    ],
    "full": [
        [1, 1, 1, 1],  # All inputs to all outputs
        [1, 1, 1, 1],
        [1, 1, 1, 1]
    ],
    "passthrough": [  # Direct connection from each input to corresponding output
        [1, 0, 0, 0],  # Pi to Pi
        [0, 1, 0, 0],  # AES to AES
        [0, 0, 1, 0]   # Analog to Analog
        # Generator input is ignored as there is no corresponding output
    ]
}

class SignalMatrix:
    def __init__(self, matrix_name='default', offsets=DEFAULT_OFFSETS):
        self.inputs = INPUTS
        self.outputs = OUTPUTS
        self.matrix_name = matrix_name
        if matrix_name in MATRICES:
            self.matrix = [row[:] for row in MATRICES[matrix_name]]
        else:
            print(f"Matrix name '{matrix_name}' not found. Available matrices are: {', '.join(MATRICES.keys())}")
            self.matrix = [row[:] for row in MATRICES['default']]
        self.offsets = offsets

    def display_matrix(self):
        print(f"Matrix: {self.matrix_name}")
        print("        " + "  ".join(self.inputs))
        for row, output in zip(self.matrix, self.outputs):
            print(f"{output}:  {'  '.join(map(str, row))}")

    def write_to_dsp(self, execute=False):
        for offset in self.offsets:
            print(f"\nWriting to DSP with offset 0x{offset:02X}")
            for row_index, row in enumerate(self.matrix):
                for col_index, value in enumerate(row):
                    cell_offset = offset + (row_index * len(self.inputs) + col_index)
                    dsp_value = 0x01000000 * value
                    command = f"dsptoolkit write-mem 0x{cell_offset:02X} 0x{dsp_value:08X}"
                    print(command)
                    if execute:
                        subprocess.run(command, shell=True)

def main():
    parser = argparse.ArgumentParser(description="Control DSP matrix routing.")
    parser.add_argument('--matrix', type=str, help="Name of the matrix to use. Options are: 'default', 'generator', 'full', 'passthrough'")
    parser.add_argument('--offsets', nargs='*', type=lambda x: int(x, 16), default=DEFAULT_OFFSETS, help="List of offsets in hexadecimal.")
    parser.add_argument('--execute', action='store_true', help="Execute DSP commands instead of just displaying them.")

    args = parser.parse_args()

    if args.matrix and args.matrix in MATRICES:
        matrix = SignalMatrix(matrix_name=args.matrix, offsets=args.offsets)
    else:
        print(f"No valid matrix name provided or unknown name. Available matrices are: {', '.join(MATRICES.keys())}")
        return

    matrix.display_matrix()
    matrix.write_to_dsp(execute=args.execute)

if __name__ == "__main__":
    main()

