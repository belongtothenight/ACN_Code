# Setup for following structure

Default structure is started from [https://github.com/belongtothenight/autotools_init_setup/tree/main/type2](https://github.com/belongtothenight/autotools_init_setup/tree/main/type2).

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

## Executable

1. tp_packet_count: Parse the trace file and count the number of packets in given time interval.
2. tp_iat: Parse the trace file and calculate the inter-arrival time of packets.
