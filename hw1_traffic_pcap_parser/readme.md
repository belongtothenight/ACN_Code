# Traffic Pcap Parser

This is a re-write version of the original code from [LAB518/Traffic_PcapParser](https://github.com/Lab518/Traffic_PcapParser)

Focuses on improving the performance of the original code by Cython.

## Time

Original code run in jupyter notebook: ~400 minutes for pcap parsing not including any other processing

## Run

native_run.ps1: Run the code with native python (for making sure cython helps, not actively developed)
cython_run.ps1: Run the code compiled with cython

## Data

[http://www.fukuda-lab.org/mawilab/v1.1/index.html](http://www.fukuda-lab.org/mawilab/v1.1/index.html)
