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
import pickle

# The input is the list of frequency count
def norm_entropy(freq_counts):
    cdef float entropy
    cdef float entropy_norm
    cdef float total_count
    cdef float prob
    cdef int distinct_count

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

cdef class parser:
    cdef list pcap_fp
    cdef list iat_delta_t
    cdef list iat_floats
    cdef list iat_delta_t_stds
    cdef list iat_delta_t_skews
    cdef list iat_delta_t_kurts
    cdef list ip_packet_counts
    cdef list ip_distinct_src_counts
    cdef list ip_distinct_dst_counts
    cdef list timestamps
    cdef list average_packet_lengths
    cdef list icmp_percentages
    cdef list tcp_percentages
    cdef list udp_percentages
    cdef list average_iats
    cdef list f2_src_ips
    cdef list f2_dst_ips
    cdef list entropy_src_ips
    cdef list entropy_dst_ips
    cdef list tcp_syn_counts
    cdef list tcp_fin_counts
    cdef float delta_t
    cdef float current_time
    cdef float previous_time
    cdef float start_time
    cdef unsigned long long int max_packets
    cdef unsigned long long int packet_count
    cdef unsigned long long int ip_packet_count
    cdef unsigned long long int packet_length
    cdef unsigned long long int sum_packet_length
    cdef unsigned long long int icmp_count
    cdef unsigned long long int tcp_count
    cdef unsigned long long int udp_count
    cdef unsigned long long int tcp_syn_count
    cdef unsigned long long int tcp_fin_count
    cdef iat
    cdef sum_iat
    ip_count_src = defaultdict(int)
    ip_count_dst = defaultdict(int)

    # Check input arguments
    def __init__(self, data) -> None:
        self.init_var()

        if not os.path.isdir(data["data_directory"]):
            raise ValueError("Invalid data_directory: " + data["data_directory"])
        if not (type(data["delta_t"]) == float or type(data["delta_t"]) == int or data["delta_t"] > 0):
            raise ValueError("Invalid delta_t: " + str(data["delta_t"]))
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

    # Initialize data structures
    def init_var(self):
        # cdef list
        self.pcap_fp = []
        self.iat_delta_t = []
        self.iat_floats = []
        self.iat_delta_t_stds = []
        self.iat_delta_t_skews = []
        self.iat_delta_t_kurts = []
        self.ip_packet_counts = []
        self.ip_distinct_src_counts = []
        self.ip_distinct_dst_counts = []
        self.timestamps = []
        self.average_packet_lengths = []
        self.icmp_percentages = []
        self.tcp_percentages = []
        self.udp_percentages = []
        self.average_iats = []
        self.f2_src_ips = []
        self.f2_dst_ips = []
        self.entropy_src_ips = []
        self.entropy_dst_ips = []
        self.tcp_syn_counts = []
        self.tcp_fin_counts = []
        # cdef float
        self.delta_t = 0
        self.current_time = 0
        self.previous_time = 0
        self.start_time = 0
        # cdef unsigned long long int
        self.max_packets = 0
        self.packet_count = 0
        self.ip_packet_count = 0
        self.packet_length = 0
        self.sum_packet_length = 0
        self.icmp_count = 0
        self.tcp_count = 0
        self.udp_count = 0
        self.tcp_syn_count = 0
        self.tcp_fin_count = 0
        # cdef
        self.iat = 0
        self.sum_iat = 0
        # defaultdict
        ip_count_src = defaultdict(int)
        ip_count_dst = defaultdict(int)

    # Reset data structures
    def reset_var(self):
        self.ip_packet_count = 0
        self.sum_packet_length = 0
        self.icmp_count = 0
        self.tcp_count = 0
        self.udp_count = 0
        self.tcp_syn_count = 0
        self.tcp_fin_count = 0
        self.sum_iat = 0
        self.ip_count_src.clear()
        self.ip_count_dst.clear()
        self.iat_delta_t = []

    # Load data into memory and parse it (linear process, can't be parallelized)
    cdef unsigned long long int tmp_size
    def load_parse(self, index, fcnt):
        print("Loading and parsing pcap file: " + self.pcap_fp[index])
        packets = PcapReader(self.pcap_fp[index])
        full_size = os.path.getsize(self.pcap_fp[index])
        self.packet_count = 0
        tmp_size = 0
        for packet in packets:
            # Break if the maximum packet count is reached
            if (self.packet_count >= self.max_packets) and (self.max_packets != 0):
                print("\nReached maximum packet count")
                break
            self.packet_count += 1

            # Print progress
            tmp_size += len((packet.summary()).encode('utf-8'))
            print("File: {0}/{1} - Progress: {2:.4f}% - Packet Count: {3}".format(index+1, fcnt, (tmp_size/full_size)*100, self.packet_count), end="\r")

            # Initialize the start time to the timestamp of the first packet
            if (self.packet_count==0):
                self.current_time = packet.time
                self.previous_time= packet.time
                self.start_time = packet.time
            else:
                self.previous_time= self.current_time
                self.current_time = packet.time

            # Existed Flow
            if IP in packet:
                self.ip_packet_count += 1
                self.ip_count_src[packet[IP].src] += 1
                self.ip_count_dst[packet[IP].dst] += 1
                self.iat = self.current_time - self.previous_time
                self.iat_delta_t.append(float(self.iat))
                self.sum_iat = self.sum_iat + self.iat
                self.sum_packet_length = self.sum_packet_length + packet[IP].len
                if packet[IP].proto == 1:
                    self.icmp_count += 1
                elif packet[IP].proto == 6:
                    self.tcp_count += 1
                    if packet[TCP].flags & 0x02:
                        self.tcp_syn_count += 1
                    if packet[TCP].flags & 0x01:
                        self.tcp_fin_count += 1
                elif packet[IP].proto == 17:
                    self.udp_count += 1
                self.previous_time = self.current_time

            # Calculate the time window data
            if ((self.current_time - self.start_time) >= self.delta_t):
                self.start_time = self.current_time
                self.ip_packet_counts.append(self.ip_packet_count)
                self.ip_distinct_src_counts.append(len(self.ip_count_src))
                self.ip_distinct_dst_counts.append(len(self.ip_count_dst))
                self.timestamps.append(self.start_time)
                if self.ip_packet_count != 0:
                    self.average_packet_lengths.append(self.sum_packet_length/self.ip_packet_count)
                    self.icmp_percentages.append(self.icmp_count/self.ip_packet_count)
                    self.tcp_percentages.append(self.tcp_count/self.ip_packet_count)
                    self.udp_percentages.append(self.udp_count/self.ip_packet_count)
                    self.average_iats.append(self.sum_iat/self.ip_packet_count)
                    self.f2_src_ips.append(sum(c1**2 for c1 in self.ip_count_src.values())/self.ip_packet_count**2)
                    self.f2_dst_ips.append(sum(c2**2 for c2 in self.ip_count_dst.values())/self.ip_packet_count**2)
                else:
                    self.average_packet_lengths.append(0)
                    self.icmp_percentages.append(0)
                    self.tcp_percentages.append(0)
                    self.udp_percentages.append(0)
                    self.average_iats.append(0)
                    self.f2_src_ips.append(0)
                    self.f2_dst_ips.append(0)
                if len(self.iat_delta_t) > 1:
                    self.iat_delta_t_stds.append(statistics.variance(self.iat_delta_t) ** 0.5)
                    self.iat_floats = [float(x) for x in self.iat_delta_t]
                    self.iat_delta_t_skews.append(skew(self.iat_floats))
                    self.iat_delta_t_kurts.append(kurtosis(self.iat_floats))
                else:
                    self.iat_delta_t_stds.append(0)
                    self.iat_delta_t_skews.append(0)
                    self.iat_delta_t_kurts.append(0)
                self.entropy_src_ips.append(norm_entropy(self.ip_count_src.values()))
                self.entropy_dst_ips.append(norm_entropy(self.ip_count_dst.values()))
                self.tcp_syn_counts.append(self.tcp_syn_count)
                self.tcp_fin_counts.append(self.tcp_fin_count)
                self.reset_var()

    # Write class mem to file
    def write(self, index):
        # Tuple Variables to be written
        data = (self.pcap_fp,
                self.iat_delta_t,
                self.iat_floats,
                self.iat_delta_t_stds,
                self.iat_delta_t_skews,
                self.iat_delta_t_kurts,
                self.ip_packet_counts,
                self.ip_distinct_src_counts,
                self.ip_distinct_dst_counts,
                self.timestamps,
                self.average_packet_lengths,
                self.icmp_percentages,
                self.tcp_percentages,
                self.udp_percentages,
                self.average_iats,
                self.f2_src_ips,
                self.f2_dst_ips,
                self.entropy_src_ips,
                self.entropy_dst_ips,
                self.tcp_syn_counts,
                self.tcp_fin_counts,
                self.delta_t,
                self.current_time,
                self.previous_time,
                self.start_time,
                self.max_packets,
                self.ip_packet_count,
                self.packet_length,
                self.sum_packet_length,
                self.icmp_count,
                self.tcp_count,
                self.udp_count,
                self.tcp_syn_count,
                self.tcp_fin_count,
                self.iat,
                self.sum_iat)
        # Write to file
        filename = os.path.dirname(self.pcap_fp[index])+ "/" + os.path.basename(self.pcap_fp[index]).split(".")[0] + ".pickle"
        with open(filename, 'wb') as f:
            pickle.dump(data, f)
        print("Data written to file: " + filename)

    # Read class mem from file
    def read(self, index):
        filename = os.path.dirname(self.pcap_fp[index])+ "/" + os.path.basename(self.pcap_fp[index]).split(".")[0] + ".pickle"
        with open(filename, 'rb') as f:
            data = pickle.load(f)
        # Tuple Variables to be read
        (self.pcap_fp,
         self.iat_delta_t,
         self.iat_floats,
         self.iat_delta_t_stds,
         self.iat_delta_t_skews,
         self.iat_delta_t_kurts,
         self.ip_packet_counts,
         self.ip_distinct_src_counts,
         self.ip_distinct_dst_counts,
         self.timestamps,
         self.average_packet_lengths,
         self.icmp_percentages,
         self.tcp_percentages,
         self.udp_percentages,
         self.average_iats,
         self.f2_src_ips,
         self.f2_dst_ips,
         self.entropy_src_ips,
         self.entropy_dst_ips,
         self.tcp_syn_counts,
         self.tcp_fin_counts,
         self.delta_t,
         self.current_time,
         self.previous_time,
         self.start_time,
         self.max_packets,
         self.ip_packet_count,
         self.packet_length,
         self.sum_packet_length,
         self.icmp_count,
         self.tcp_count,
         self.udp_count,
         self.tcp_syn_count,
         self.tcp_fin_count,
         self.iat,
         self.sum_iat) = data
        print("Data read from file: " + filename)

    # Write critical data to file
    def write_critical(self, index):
        filename = os.path.dirname(self.pcap_fp[index])+ "/" + os.path.basename(self.pcap_fp[index]).split(".")[0] + "_critical.txt"
        with open(filename, 'w') as f:
            for item1, item2,item3, item4,item5, item6,item7, item8,item9, item10,item11,item12, item13,item14,item15,item16,item17 in zip(
                self.timestamps,
                self.ip_packet_counts,
                self.ip_distinct_src_counts,
                self.ip_distinct_dst_counts,
                self.f2_src_ips,
                self.f2_dst_ips,
                self.average_iats,
                self.iat_delta_t_skews,
                self.iat_delta_t_kurts,
                self.entropy_src_ips,
                self.entropy_dst_ips,
                self.average_packet_lengths,
                self.icmp_percentages,
                self.tcp_percentages,
                self.udp_percentages,
                self.tcp_syn_counts,
                self.tcp_fin_counts):
                f.write(f"{item1}\t{item2}\t{item3}\t{item4}\t{item5}\t{item6}\t{item7}\t{item8}\t{item8}\t{item9}\t{item10}\t{item11}\t{item12}\t{item13}\t{item14}\t{item15}\t{item16}\t{item17}\n")
        print("Critical data written to file: " + filename)

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
            self.write_critical(i)
            self.write(i)
            self.read(i)

    # Plot data
    def plot(self):
        print("Plotting data")

data = {
    "data_directory": "E:/GitHub/ACN_Code/hw1_traffic_pcap_parser/data/",
    "delta_t": 10.0,
    "max_packets": 100000,
}
p = parser(data)
p.exec()
p.plot()
