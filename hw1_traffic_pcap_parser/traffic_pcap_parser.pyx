from scapy.all import IP, TCP, PcapReader
from collections import defaultdict
from scipy.stats import skew, kurtosis
import matplotlib.pyplot as plt
import time
import timeit
import numpy as np
import statistics
import math
import os
import multiprocessing

"""
TIME
Original code run in jupyter notebook: ~400 minutes
"""

"""
COMPILE
C:\Python312\python.exe -m pip install cython setuptools
cp traffic_pcap_parser.pyx traffic_pcap_parser.py; C:\Python312\python.exe traffic_pcap_parser.py; rm traffic_pcap_parser.py
C:\Python312\python.exe .\setup.py build_ext --inplace; C:\Python312\python.exe .\execute.py
"""

class parser:
    # Check input arguments
    def __init__(self, data) -> None:
        print("Initializing parser")
        if not os.path.isdir(data["data_directory"]):
            raise ValueError("Invalid data_directory: " + data["data_directory"])
        if not (type(data["delta_t"]) == float or type(data["delta_t"]) == int or data["delta_t"] > 0):
            raise ValueError("Invalid delta_t: " + str(data["delta_t"]))
        self.pcap_fp = []
        for dirpath, dirnames, filenames in os.walk(data["data_directory"]):
            if len(filenames) == 0:
                raise ValueError("No pcap files found in data_directory: " + data["data_directory"])
            for filename in filenames:
                if ".pcap" in filename:
                    self.pcap_fp.append(os.path.join(dirpath, filename))
        if len(self.pcap_fp) == 0:
            raise ValueError("No pcap files found in data_directory: " + data["data_directory"])
        print("Found " + str(len(self.pcap_fp)) + " pcap files")
        self.delta_t = data["delta_t"]
        self.max_packets = data["max_packets"]
        self.common = {
                "packet_cnt": 0,
                "ip_packet_cnt": 0,
                "ip_cnt_src": defaultdict(int),
                "ip_cnt_dst": defaultdict(int),
                "ip_packet_cnts": [], #?? Dup?
                "average_IATs": [],
                "IAT_list_delta_t": [],
                "IAT_list_delta_t_std": [],
                "IAT_list_delta_t_skew": [],
                "IAT_list_delta_t_kurtosise": [],
                "sum_IAT": 0,
                }
        self.entropy = {
                "freq_cnt_src": [],
                "freq_cnt_dst": [],
                "ip_cnt_distinct_src": [],
                "ip_cnt_distinct_dst": [],
                "f2_src_ip": [],
                "f2_dst_ip": [],
                "timestamp": [],
                "src_ip": [], #entropys_srcIP
                "dst_ip": [], #entropys_destIP
                }
        self.ip_length = {
                "average_packet_length": [],
                "sum_packet_length": 0,
                }
        self.protocol = {
                "ICMP_percentage": [],
                "TCP_percentage": [],
                "UDP_percentage": [],
                "ICMP_cnt": 0,
                "TCP_cnt": 0,
                "UDP_cnt": 0,
                }
        self.tcp = {
                "syn_cnt": 0,
                "fin_cnt": 0,
                "syn_cnt_list": [],
                "fin_cnt_list": [],
                }
        self.time = {
                "current_time": 0,
                "previous_time": 0,
                "start_time": 0,
                }


    # Load data into memory and parse it (linear process, can't be parallelized)
    def load_parse(self, index, fcnt):
        print("Loading and parsing pcap file: " + self.pcap_fp[index])
        packets = PcapReader(self.pcap_fp[index])
        full_size = os.path.getsize(self.pcap_fp[index])
        tmp_size = 0
        pkt_cnt = 0
        for packet in packets:
            if (pkt_cnt >= self.max_packets):
                break
            tmp_size += len((packet.summary()).encode('utf-8'))
            pkt_cnt += 1
            print("File: {0}/{1} - Progress: {2:.4f}% - Packet Count: {3}".format(index+1, fcnt, (tmp_size/full_size)*100, pkt_cnt), end="\r")
            if (self.common["packet_cnt"] == 0):
                # Initialize time
                self.time["current_time"] = packet.time
                self.time["previous_time"] = packet.time
                self.time["start_time"] = packet.time
            else:
                self.time["previous_time"] = self.time["current_time"]
                self.time["current_time"] = packet.time
            self.common["packet_cnt"] += 1

    # (multi-processing is difficult for concurrent data access)
    def exec(self):
        total_tasks = len(self.pcap_fp)
        #if total_tasks < os.cpu_count():
        #    tasks = total_tasks
        #else:
        #    tasks = os.cpu_count()
        #with multiprocessing.Pool(tasks) as pool:
        #    pool.map(self.load_parse, range(total_tasks))
        #pool.close()
        #pool.join()
        for i in range(total_tasks):
            init_time = time.time()
            self.load_parse(i, total_tasks)
            print("Time taken for file {0}/{1}: {2:.4f} seconds".format(i+1, total_tasks, time.time()-init_time))

    # Plot data
    def plot(self):
        print("Plotting data")

data = {
    "data_directory": "E:/GitHub/ACN_Code/hw1_traffic_pcap_parser/data/",
    "delta_t": 10.0,
    "max_packets": 10000,
}
p = parser(data)
p.exec()
p.plot()
