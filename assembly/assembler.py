def read_file(filename):
    with open(filename) as file:
        return file.readlines()


opcodes = {
        'addi': 0b0110111,
        'add' : 0b0110011,
        'sw'  : 0b0100011,
        'jalr': 0b1100111
        }

def parse_instructions(lines):
    for line in lines:
        inst = line.split(' ')[0]
        if inst == opcodes:
            params = line.split(' ')

parse_instructions(read_file('fib.asm'))
