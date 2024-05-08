# Setup for following structure

Default structure is started from [https://github.com/belongtothenight/autotools_init_setup/tree/main/type2](https://github.com/belongtothenight/autotools_init_setup/tree/main/type2).

These program is only developed on debian based Linux system.

## Usage

General user and standard deployment use [../hw4_libtrace_setup](../hw4_libtrace_setup) to compile the code.

Developer can use following command to compile the code.

```bash
./bootstrap.sh && ./configure && make
sudo make install
```

Remember to run the following command before committing the code.

```bash
sudo make uninstall
make clean
```

## Parse Trace Executable

Note: All executables can use `-h` or `--help` to show the help/usage message.

1. pt_count_packet: Parse the trace file and count the number of packets in given time interval.
2. pt_quantize_iat: Parse the trace file and calculate the Inter-Arrival Time (IAT) of packets. Optionally, it can use GNUplot to plot histogram of IAT.

## Debug

- compiling get following error message:
    ```bash
    ./configure.ac: line 10: syntax error near unexpected token \`[2.71]\'
    ./configure.ac: line 10: \`AC_PREREQ([2.71])\'
    ```
    - Solution: Don't execute `./configure` as `./configure.ac`. Tab completion is causing this issue.
