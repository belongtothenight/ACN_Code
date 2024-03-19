# Traffic Pcap Parser

This is a re-write version of the original code from [LAB518/Traffic_PcapParser](https://github.com/Lab518/Traffic_PcapParser)

Focuses on improving the performance of the original code by Cython.

Note: Cython version of the code doesn't support memory dump.

## Hardware Recommendation

```
CPU:  High single core score
SWAP: 64GB
RAM:  "read_mode" = 1, RAM >= pcap file size times 40
RAM:  plotting f12~18 requires 48GB RAM, recommended 64GB (3.6GB pcap file)
```

## Time

```
Following code only perform original pcap parsing.
Original code in jupyter notebook: ~400 min (202301301400)
Original code in python native ([./traffic_pcap_parser.py](./traffic_pcap_parser.py)): ~387 min (202301261400)
Re-write code in cython ([./traffic_pcap_parser.pyx](./traffic_pcap_parser.pyx)): ~449 min (202301261400) (dual launched)
Re-write code in python native (auto-generated from cython version): ~443 min (202301261400) (dual launched)
```

## Run

native_run.ps1: Run the code with native python (port from original code)
cython_run.ps1: Run the code compiled with cython (develop focused)
native_re_run.ps1: Run the re-write code with native python (port from cython code)

## Data

[http://www.fukuda-lab.org/mawilab/v1.1/index.html](http://www.fukuda-lab.org/mawilab/v1.1/index.html)

## Code Flow Improvement (for speed)

1. Use Cython to compile the code. (Refers to .pyx file)
2. Use [This Solution](https://stackoverflow.com/questions/14456513/speed-up-python-loop-processing-packets) to push the loop into C level.

## Focused Packet Layers

1. TCP
2. UDP
3. ICMP

[https://scapy.readthedocs.io/en/latest/api/scapy.layers.inet.html#scapy.layers.inet.IP.payload_guess](https://scapy.readthedocs.io/en/latest/api/scapy.layers.inet.html#scapy.layers.inet.IP.payload_guess)
[https://scapy.readthedocs.io/en/latest/api/scapy.layers.inet.html#scapy.layers.inet.TCP.payload_guess](https://scapy.readthedocs.io/en/latest/api/scapy.layers.inet.html#scapy.layers.inet.TCP.payload_guess)
