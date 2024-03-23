# Traffic Pcap Parser

This is a re-write version of the original code from [LAB518/Traffic_PcapParser](https://github.com/Lab518/Traffic_PcapParser)

Focuses on improving the performance of the original code by Cython, and add additional functionalities for ease of use.

Note: Cython version of the code doesn't support memory dump.

## Requirement

- awk/gawk
- (windows) python3.12
- (linux) python3
- (python/pip) matplotlib scapy scipy
- (parsing/plotting) pcap file in "data" directory
- (plotting) pickle file in "mem_dump" directory

## Structure/Execution

- [native_run.ps1](native_run.ps1)/[native_run.sh](native_run.sh): Run the code with native python (port from original code)
- [cython_run.ps1](cython_run.ps1)/[cython_run.sh](cython_run.sh): Run the code compiled with cython (develop focused, doesn't support memory dump and recover)
- [native_re_run.ps1](native_re_run.ps1)/[native_re_run.sh](native_re_run.sh): Run the re-write code with native python (port from cython code)
- [native_plot_re_run.ps1](native_plot_re_run.ps1)/[native_plot_re_run.sh](native_plot_re_run.sh): Run the re-write code with native python to perform multiprocessing plotting.

- [.gitignore](.gitignore): Commit filter.
- [plotting.py](plotting.py): Import parser class from Cython file and execute with multiprocessing. 
- [readme.md](readme.md): This file.
- [traffic_pcap_parser.py](traffic_pcap_parser.py): Original JupyterNotebook code directly ported to native Python.
- [traffic_pcap_parser.pyx](traffic_pcap_parser.pyx): Rewrite parsing code frim original version and add support for: input interdace, protocol port support, more data plotting (3D), class memory dump and recover.

## Functionality (re-write)

1. Input interface easy to integrate with other code. (walk through all pcap files in a directory, multi-processing, etc.)
2. Memory dump and recover, separate the parsing and plotting process. (plotting requires large amount of memory; this is not supported in cython version)
3. Both powershell and bash scripts are provided for easy execution and minimum repository size.
4. Set maximum packet count or interval count for quick testing on parsing function.
5. Set interval count to limit data displayed in the plot.

## Hardware Recommendation (re-write)

```
CPU:  High single core score
SWAP: 128GB (or use swapspace to dynamically allocate swap size)
RAM(SWAP):  "read_mode" = 1, >= pcap file size times 40; "read_mode" = 0, ~= 10GB (3.6GB pcap.gz file)
RAM(SWAP):  plotting f12~15 requires 48GB RAM, recommended 64GB (3.6GB pcap.gz file)
RAM(SWAP):  plotting f16~18 requires 80GB RAM, recommended 128GB (3.6GB pcap.gz file)
```

Windows platform will support medium amount of auto-swapping, but can't handle large swap size (Exact size is hard to tell). If python gives "memory error" during plotting, it is recommended to use WSL with 32GB RAM and 128GB SWAP ([setup](https://youtu.be/Tu95sdnALJk?si=TzmAeBTVXM0doXC6)) or native Linux system with [swapspace by rubo77](https://unix.stackexchange.com/a/134372) enabled.

## Time

```
Following code only perform original pcap parsing.
Original code in jupyter notebook: ~400 min (202301301400)
Original code in python native ([./traffic_pcap_parser.py](./traffic_pcap_parser.py)): ~387 min (202301261400)
Re-write code in cython ([./traffic_pcap_parser.pyx](./traffic_pcap_parser.pyx)): ~449 min (202301261400) (dual launched)
Re-write code in python native (auto-generated from cython version): ~443 min (202301261400) (dual launched)
```

## Documentation(re-write)

### Code Flow Improvement (for speed)

1. Use Cython to compile the code. (Refers to .pyx file)
2. Use [This Solution](https://stackoverflow.com/questions/14456513/speed-up-python-loop-processing-packets) to push the loop into C level.

### Data

[http://www.fukuda-lab.org/mawilab/v1.1/index.html](http://www.fukuda-lab.org/mawilab/v1.1/index.html)

### Focused Packet Layers

1. TCP
2. UDP
3. ICMP

[https://scapy.readthedocs.io/en/latest/api/scapy.layers.inet.html#scapy.layers.inet.IP.payload_guess](https://scapy.readthedocs.io/en/latest/api/scapy.layers.inet.html#scapy.layers.inet.IP.payload_guess)  
[https://scapy.readthedocs.io/en/latest/api/scapy.layers.inet.html#scapy.layers.inet.TCP.payload_guess](https://scapy.readthedocs.io/en/latest/api/scapy.layers.inet.html#scapy.layers.inet.TCP.payload_guess)  

### Class Documentation

- ```parser.__init__```: Initialize data structures and check input data dictionary values.
- ```parser.init_var``` (private): Initialize data structures.
- ```parser.reset_var``` (private): Reset data structures when parsing interval changes.
- ```parser.load_parse```: Load and parse pcap file. (can be gunzip files)
- ```parser.print_critical``` (private): Print critical information during parsing interval to verify parsing result.
- ```parser.write```: Dump data structures to file.
- ```parser.read```: Load data structures from file.
- ```parser.write_critical```: Write critical information to file.
- ```parser.exec```: Execute the parser with preset work flow. (include ```parser.__init__```, ```parser.load_parse```, ```parser.write_critical```, ```parser.write```)
- ```parser.plot```: Plot data structures to figures.
