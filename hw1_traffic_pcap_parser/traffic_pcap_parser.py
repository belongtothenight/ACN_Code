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

# The input is the list of frequency count
def norm_entropy(freq_counts):
    total_count = sum( freq_counts)
    probabilities = [count / total_count for count in freq_counts]
    entropy = 0
    for prob in probabilities:
        if prob > 0:
            entropy -= prob * math.log(prob, 2)
    #normalize the entropy
    distinct_count=len(freq_counts)
    #just in case only one distinct count
    if (distinct_count<=1):
        entropy_norm=0
    else:
        entropy_norm=entropy/math.log(distinct_count, 2)
    return entropy_norm
# the list of data contain the original elements    
def raw_entropy(data):
    """Compute the entropy of a list of integers"""
    if not data:
        return 0
    counts = {}
    for value in data:
        counts[value] = counts.get(value, 0) + 1
    probs = [float(c) / len(data) for c in counts.values()]
    entropy_raw=-sum(p * math.log(p, 2) for p in probs)
    return entropy_raw

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
        ##########
        # Create a dictionary to count packets and distinct IP addresses
        ##########
        self.packet_count = 0
        self.ip_packet_count =0
        self.ip_count_src = []
        self.ip_count_dest = []
        self.ip_packet_counts = []
        self.average_IATs=[]
        self.IAT_list_deltaT=[]
        self.IAT_list_deltaT_stds=[]
        self.IAT_list_deltaT_skews=[]
        self.IAT_list_deltaT_kurts=[]
        self.sum_iat=0
        self.ip_count_src = defaultdict(int)
        self.ip_count_dest = defaultdict(int)
        
        #for entropy
        self.freq_count_src=[]
        self.freq_count_dest=[]
        self.ip_counts_distinct_src = []
        self.ip_counts_distinct_dest = []
        self.F2_srcIPs= []
        self.F2_destIPs= []
        self.time_stamps = []

        #IPLength
        self.average_packet_lengths = []
        self.sum_pkt_length=0
        
        #Protocols
        self.ICMP_percentages=[]
        self.TCP_percentages=[]
        self.UDP_percentages=[]
        self.icmp_count=0
        self.tcp_count=0
        self.udp_count=0

        # Initialize TCP syn fin counters
        self.syn_count = 0
        self.fin_count = 0
        self.syn_counts = []
        self.fin_counts = []
        self.entropys_srcIP=[]
        self.entropys_destIP=[]
        self.current_time = 0
        self.previous_time= 0
        self.start_time = 0

    # Load data into memory and parse it (linear process, can't be parallelized)
    def load_parse(self, index, fcnt):
        print("Loading and parsing pcap file: " + self.pcap_fp[index])
        packets = PcapReader(self.pcap_fp[index])
        full_size = os.path.getsize(self.pcap_fp[index])
        tmp_size = 0
        pkt_cnt = 0
        for packet in packets:
            if (pkt_cnt >= self.max_packets) and (self.max_packets != 0):
                print("\nReached maximum packet count")
                break
            tmp_size += len((packet.summary()).encode('utf-8'))
            pkt_cnt += 1
            print("File: {0}/{1} - Progress: {2:.4f}% - Packet Count: {3}".format(index+1, fcnt, (tmp_size/full_size)*100, pkt_cnt), end="\r")
            if (self.packet_count==0):
                # Initialize the start time to the timestamp of the first packet
                # Get the first packet in the pcap file
                self.current_time = packet.time
                self.previous_time= packet.time
                self.start_time = packet.time
            else:
                self.previous_time= self.current_time
                self.current_time = packet.time
            self.packet_count += 1

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
