#! /bin/bash                         

# Created by Lubos Kuzma             
# ISS Program, SADT, SAIT
# August 2022

if [ $# -lt 1 ]; then               # Checks if the number of command-line arguments is less than 1
    echo "Usage:"                    # Prints usage information if the condition is true
    echo ""
    echo "x86_toolchain.sh [ options ] <assembly filename> [-o | --output <output filename>]"
    echo ""
    echo "-v | --verbose                Show some information about steps performed."
    echo "-g | --gdb                    Run gdb command on executable."
    echo "-b | --break <break point>    Add breakpoint after running gdb. Default is _start."
    echo "-r | --run                    Run program in gdb automatically. Same as run command inside gdb env."
    echo "-q | --qemu                   Run executable in QEMU emulator. This will execute the program."
    echo "-32| --x86-32                 Compile for 32bit (x86) system."
    echo "-o | --output <filename>      Output filename."

    exit 1                          # Exits the script with status 1 (indicating an error)
fi

POSITIONAL_ARGS=()                  # Declares an array to store positional arguments
GDB=False                           # Initializes a variable to store whether gdb will be used
OUTPUT_FILE=""                      # Initializes a variable to store the output file name
VERBOSE=False                       # Initializes a variable to store whether verbose mode is enabled
BITS=True                           # Initializes a variable to store whether 64-bit mode is enabled (default)
QEMU=False                          # Initializes a variable to store whether QEMU will be used
BREAK="_start"                      # Initializes a variable to store the breakpoint name
RUN=False                           # Initializes a variable to store whether program will be run automatically in gdb
while [[ $# -gt 0 ]]; do            # Loops through all command-line arguments
    case $1 in                      # Checks each argument
        -g|--gdb)                   # If argument is -g or --gdb
            GDB=True                # Set GDB variable to True
            shift                   # Move to the next argument
            ;;
        -o|--output)                # If argument is -o or --output
            OUTPUT_FILE="$2"        # Store the next argument as the output file name
            shift                   # Move to the next argument
            shift                   # Move past the value of the output file name
            ;;
        -v|--verbose)               # If argument is -v or --verbose
            VERBOSE=True            # Set VERBOSE variable to True
            shift                   # Move to the next argument
            ;;
        -32|--x86-32)               # If argument is -32 or --x86-32
            BITS=False              # Set BITS variable to False (32-bit mode)
            shift                   # Move to the next argument
            ;;
        -q|--qemu)                  # If argument is -q or --qemu
            QEMU=True               # Set QEMU variable to True
            shift                   # Move to the next argument
            ;;
        -r|--run)                   # If argument is -r or --run
            RUN=True                # Set RUN variable to True
            shift                   # Move to the next argument
            ;;
        -b|--break)                 # If argument is -b or --break
            BREAK="$2"              # Store the next argument as the breakpoint name
            shift                   # Move to the next argument
            shift                   # Move past the value of the breakpoint name
            ;;
        -*|--*)                     # If argument starts with "-" or "--"
            echo "Unknown option $1"   # Print an error message for unknown options
            exit 1                  # Exit the script with status 1 (indicating an error)
            ;;
        *)                          # For any other argument
            POSITIONAL_ARGS+=("$1") # Store the argument as a positional argument
            shift                   # Move to the next argument
            ;;
    esac
done

set -- "${POSITIONAL_ARGS[@]}"     # Restore positional parameters

if [[ ! -f $1 ]]; then              # If the first positional argument is not a file
    echo "Specified file does not exist" # Print an error message
    exit 1                          # Exit the script with status 1 (indicating an error)
fi

if [ "$OUTPUT_FILE" == "" ]; then  # If output file name is not provided
    OUTPUT_FILE=${1%.*}            # Set output file name based on the input file name
fi

if [ "$VERBOSE" == "True" ]; then  # If verbose mode is enabled
    echo "Arguments being set:"    # Print information about the arguments being set
    echo "    GDB = ${GDB}"
    echo "    RUN = ${RUN}"
    echo "    BREAK = ${BREAK}"
    echo "    QEMU = ${QEMU}"
    echo "    Input File = $1"
    echo "    Output File = $OUTPUT_FILE"
    echo "    Verbose = $VERBOSE"
    echo "    64 bit mode = $BITS" 
    echo ""

    echo "NASM started..."          # Print a message indicating NASM has started
fi

if [ "$BITS" == "True" ]; then     # If 64-bit mode is enabled
    nasm -f elf64 $1 -o $OUTPUT_FILE.o && echo ""  # Assemble the input file into ELF64 format
else                                # Otherwise (32-bit mode)
    nasm -f elf $1 -o $OUTPUT_FILE.o && echo ""    # Assemble the input file into ELF format
fi

if [ "$VERBOSE" == "True" ]; then  # If verbose mode is enabled
    echo "NASM finished"           # Print a message indicating NASM has finished
    echo "Linking ..."             # Print a message indicating the linking process is starting
fi

if [ "$BITS" == "True" ]; then     # If 64-bit mode is enabled
    ld -m elf_x86_64 $OUTPUT_FILE.o -o $OUTPUT_FILE && echo ""  # Link the object file into an executable (64-bit)
else                                # Otherwise (32-bit mode)
    ld -m elf_i386 $OUTPUT_FILE.o -o $OUTPUT_FILE && echo ""    # Link the object file into an executable (32-bit)
fi

if [ "$VERBOSE" == "True" ]; then  # If verbose mode is enabled
    echo "Linking finished"        # Print a message indicating the linking process has finished
fi

if [ "$QEMU" == "True" ]; then     # If QEMU mode is enabled
    echo "Starting QEMU ..."       # Print a message indicating QEMU is starting
    echo ""

    if [ "$BITS" == "True" ]; then # If 64-bit mode is enabled
        qemu-x86_64 $OUTPUT_FILE && echo ""  # Execute the executable using QEMU (64-bit)
    else                            # Otherwise (32-bit mode)
        qemu-i386 $OUTPUT_FILE && echo ""    # Execute the executable using QEMU (32-bit)
    fi

    exit 0                          # Exit the script with status 0 (indicating success)
fi

if [ "$GDB" == "True" ]; then      # If GDB mode is enabled
    gdb_params=()                   # Declare an array to store gdb parameters
    gdb_params+=(-ex "b ${BREAK}") # Add a breakpoint parameter to the array

    if [ "$RUN" == "True" ]; then  # If automatic run mode in GDB is enabled
        gdb_params+=(-ex "r")       # Add a run parameter to the array
    fi

    gdb "${gdb_params[@]}" $OUTPUT_FILE # Run GDB with specified parameters and the executable
fi
