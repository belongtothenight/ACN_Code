# To utilize all CPU cores to process, modify following code by
# 1. Use multiprocessing from example code below to parallelize parser class execution (outside of the class)
        #total_tasks = len(self.pcap_fp)
        #if total_tasks < os.cpu_count():
        #    tasks = total_tasks
        #else:
        #    tasks = os.cpu_count()
        #with multiprocessing.Pool(tasks) as pool:
        #    pool.map(self.load_parse, range(total_tasks))
        #pool.close()
        #pool.join()

from scapy.all import IP, TCP, UDP, PcapReader, rdpcap
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
    cdef list tcp_src_ports # [[t1_port1, t1_port2], [t2_port1, t2_port2], ...]]
    cdef list tcp_dst_ports # [[t1_port1, t1_port2], [t2_port1, t2_port2], ...]]
    cdef list udp_src_ports # [[t1_port1, t1_port2], [t2_port1, t2_port2], ...]]
    cdef list udp_dst_ports # [[t1_port1, t1_port2], [t2_port1, t2_port2], ...]]
    cdef list tcp_src_port_distinct
    cdef list tcp_dst_port_distinct
    cdef list udp_src_port_distinct
    cdef list udp_dst_port_distinct
    cdef list tcp_src_port_counts # Count of TCP source port (by interval/delta_t)
    cdef list tcp_dst_port_counts # Count of TCP destination port (by interval/delta_t)
    cdef list udp_src_port_counts # Count of UDP source port (by interval/delta_t)
    cdef list udp_dst_port_counts # Count of UDP destination port (by interval/delta_t)
    cdef unsigned long long int int_temp
    cdef unsigned long long int display_critical
    cdef unsigned long long int interval_cnt
    cdef unsigned long long int read_mode
    cdef unsigned long long int progress_display_mode
    cdef unsigned long long int n_delta_t
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
    cdef str_temp
    cdef pcap_fp
    cdef delta_t
    cdef current_time
    cdef previous_time
    cdef start_time
    cdef iat
    cdef sum_iat
    cdef ip_count_src
    cdef ip_count_dst
    cdef init_time

    # Check input arguments
    def __init__(self, data) -> None:
        self.init_var()
        if not os.path.isfile(data["data_fp"]):
            raise ValueError("Invalid data filepath: " + data["data_fp"])
        if not (type(data["delta_t"]) == float or type(data["delta_t"]) == int or data["delta_t"] > 0):
            raise ValueError("Invalid delta_t: " + str(data["delta_t"]))
        self.pcap_fp = data["data_fp"]
        self.delta_t = data["delta_t"]
        self.read_mode = data["read_mode"]
        self.progress_display_mode = data["progress_display_mode"]
        self.display_critical = data["display_critical"]
        self.max_packets = data["max_packets"]
        self.n_delta_t = data["n_delta_t"]
        print()
        self.str_temp = ">> self.pcap_fp:                {}"
        print(self.str_temp.format(self.pcap_fp))
        self.str_temp = ">> self.delta_t:                {}"
        print(self.str_temp.format(self.delta_t))
        self.str_temp = ">> self.read_mode:              {}"
        print(self.str_temp.format("Packet stream" if self.read_mode == 0 else "Load into memory"))
        self.str_temp = ">> self.progress_display_mode:  {}"
        print(self.str_temp.format("By packet (more resource)" if self.progress_display_mode == 0 else "By interval/delta_t (less resource)"))
        self.str_temp = ">> self.display_critical:       {}"
        print(self.str_temp.format("On" if self.display_critical == 1 else "Off"))
        self.str_temp = ">> self.max_packets:            {}"
        print(self.str_temp.format("No limit" if self.max_packets == 0 else self.max_packets))
        self.str_temp = ">> self.n_delta_t:              {}"
        print(self.str_temp.format("No limit" if self.n_delta_t == 0 else self.n_delta_t))
        print("=============================================")

    # Initialize data structures
    def init_var(self):
        # cdef list
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
        self.tcp_src_ports = [[]]
        self.tcp_dst_ports = [[]]
        self.udp_src_ports = [[]]
        self.udp_dst_ports = [[]]
        self.tcp_src_port_distinct = []
        self.tcp_dst_port_distinct = []
        self.udp_src_port_distinct = []
        self.udp_dst_port_distinct = []
        self.tcp_src_port_counts = []
        self.tcp_dst_port_counts = []
        self.udp_src_port_counts = []
        self.udp_dst_port_counts = []
        # cdef unsigned long long int
        self.int_temp = 0
        self.display_critical = 0
        self.interval_cnt = 0
        self.read_mode = 1
        self.progress_display_mode = 1
        self.n_delta_t = 0
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
        self.str_temp = ""
        self.pcap_fp = ""
        self.delta_t = 0
        self.current_time = 0
        self.previous_time = 0
        self.start_time = 0
        self.iat = 0
        self.sum_iat = 0
        self.ip_count_src = defaultdict(int)
        self.ip_count_dst = defaultdict(int)
        self.init_time = time.time()

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
    def load_parse(self):
        print(">> Loading and parsing pcap file:\t" + self.pcap_fp)
        if self.read_mode == 0:
            packets = PcapReader(self.pcap_fp)
        elif self.read_mode == 1:
            print(">> Reading pcap file into memory, this may take a while...")
            print(">> If error occurs, your system may not have enough memory to load the entire pcap file (require 40+ times space), try to split the pcap file into multiple ones; or set read_mode to 0 to read the pcap file by packet.")
            print(">> Open Task Manager or other system monitor tools to check memory usage for main, cached, and swap memory usage.")
            init_time = timeit.default_timer()
            packets = rdpcap(self.pcap_fp)
            print(">> Time to read pcap file: {0:.4f} seconds".format(timeit.default_timer() - init_time))
        else:
            raise ValueError("Invalid read_mode: " + str(self.read_mode))
        if self.progress_display_mode == 0:
            full_size = os.path.getsize(self.pcap_fp)
            tmp_size = 0
        elif self.progress_display_mode == 1:
            print(">> Progress will only be displayed when each interval is processed, please wait...")
        else:
            raise ValueError("Invalid progress_display_mode: " + str(self.progress_display_mode))
        for packet in packets:
            # Initialize the start time to the timestamp of the first packet
            if (self.packet_count==0):
                self.current_time = packet.time
                self.previous_time= packet.time
                self.start_time = packet.time
            else:
                self.previous_time= self.current_time
                self.current_time = packet.time
            self.packet_count += 1

            # Break if the maximum packet count is reached
            if self.max_packets != 0:
                if self.packet_count > self.max_packets:
                    print("\n>> Reached maximum packet count")
                    break

            # Print progress
            if self.progress_display_mode == 0:
                tmp_size += len((packet.summary()).encode('utf-8'))
                print("Progress: {0:.4f}% (size) - Packet Count: {1}".format((tmp_size/full_size)*100, self.packet_count), end="\r")

            # Is Valid Packet
            if IP in packet:
                self.ip_packet_count += 1
                self.ip_count_src[packet[IP].src] += 1
                self.ip_count_dst[packet[IP].dst] += 1
                self.iat = self.current_time - self.previous_time
                self.iat_delta_t.append(float(self.iat))
                self.sum_iat += self.iat
                self.sum_packet_length += packet[IP].len
                if packet[IP].proto == 1:
                    self.icmp_count += 1
                elif packet[IP].proto == 6:
                    self.tcp_count += 1
                elif packet[IP].proto == 17:
                    self.udp_count += 1
                if TCP in packet:
                    if packet[TCP].flags & 0x02:
                        self.tcp_syn_count += 1
                    if packet[TCP].flags & 0x01:
                        self.tcp_fin_count += 1
                    self.tcp_src_ports[self.interval_cnt].append(packet[TCP].sport)
                    self.tcp_dst_ports[self.interval_cnt].append(packet[TCP].dport)
                    if packet[TCP].sport not in self.tcp_src_port_distinct:
                        self.tcp_src_port_distinct.append(packet[TCP].sport)
                    if packet[TCP].dport not in self.tcp_dst_port_distinct:
                        self.tcp_dst_port_distinct.append(packet[TCP].dport)
                if UDP in packet:
                    self.udp_src_ports[self.interval_cnt].append(packet[UDP].sport)
                    self.udp_dst_ports[self.interval_cnt].append(packet[UDP].dport)
                    if packet[UDP].sport not in self.udp_src_port_distinct:
                        self.udp_src_port_distinct.append(packet[UDP].sport)
                    if packet[UDP].dport not in self.udp_dst_port_distinct:
                        self.udp_dst_port_distinct.append(packet[UDP].dport)
                self.previous_time = self.current_time

            # Calculate the time window data
            if ((self.current_time - self.start_time) >= self.delta_t):
                self.start_time = self.current_time
                self.ip_packet_counts.append(self.ip_packet_count)
                self.ip_distinct_src_counts.append(len(self.ip_count_src))
                self.ip_distinct_dst_counts.append(len(self.ip_count_dst))
                self.timestamps.append(self.start_time)
                self.entropy_src_ips.append(norm_entropy(self.ip_count_src.values()))
                self.entropy_dst_ips.append(norm_entropy(self.ip_count_dst.values()))
                self.tcp_syn_counts.append(self.tcp_syn_count)
                self.tcp_fin_counts.append(self.tcp_fin_count)
                self.tcp_src_ports.append([])
                self.tcp_dst_ports.append([])
                self.udp_src_ports.append([])
                self.udp_dst_ports.append([])
                self.tcp_src_port_counts.append(len(self.tcp_src_ports[self.interval_cnt]))
                self.tcp_dst_port_counts.append(len(self.tcp_dst_ports[self.interval_cnt]))
                self.udp_src_port_counts.append(len(self.udp_src_ports[self.interval_cnt]))
                self.udp_dst_port_counts.append(len(self.udp_dst_ports[self.interval_cnt]))
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
                if self.progress_display_mode == 1:
                    print("Progress: {0:.4f} seconds - Packet Count: {1} - Run Time: {2:.4f} seconds".format((self.interval_cnt+1)*self.delta_t, self.packet_count, time.time() - self.init_time), end="\r")
                if self.display_critical == 1:
                    self.print_critical()
                self.reset_var()
                self.interval_cnt += 1
                if self.n_delta_t != 0:
                    if self.interval_cnt >= self.n_delta_t:
                        print("\n>> Reached maximum delta_t count")
                        break

    # Print critical data
    def print_critical(self):
        print()
        print(f"self.packet_count: {self.packet_count}")
        print(f"self.timestamps: {self.timestamps}")
        print(f"self.ip_packet_counts: {self.ip_packet_counts}")
        print(f"self.ip_distinct_src_counts: {self.ip_distinct_src_counts}")
        print(f"self.ip_distinct_dst_counts: {self.ip_distinct_dst_counts}")
        print(f"self.f2_src_ips: {self.f2_src_ips}")
        print(f"self.f2_dst_ips: {self.f2_dst_ips}")
        print(f"self.average_iats: {self.average_iats}")
        print(f"self.iat_delta_t_skews: {self.iat_delta_t_skews}")
        print(f"self.iat_delta_t_kurts: {self.iat_delta_t_kurts}")
        print(f"self.entropy_src_ips: {self.entropy_src_ips}")
        print(f"self.entropy_dst_ips: {self.entropy_dst_ips}")
        print(f"self.average_packet_lengths: {self.average_packet_lengths}")
        print(f"self.icmp_percentages: {self.icmp_percentages}")
        print(f"self.tcp_percentages: {self.tcp_percentages}")
        print(f"self.udp_percentages: {self.udp_percentages}")
        print(f"self.tcp_syn_counts: {self.tcp_syn_counts}")
        print(f"self.tcp_fin_counts: {self.tcp_fin_counts}")
        print(f"len(self.tcp_src_port_distinct): {len(self.tcp_src_port_distinct)}")
        print(f"len(self.tcp_dst_port_distinct): {len(self.tcp_dst_port_distinct)}")
        print(f"len(self.udp_src_port_distinct): {len(self.udp_src_port_distinct)}")
        print(f"len(self.udp_dst_port_distinct): {len(self.udp_dst_port_distinct)}")
        print(f"self.tcp_src_port_counts: {self.tcp_src_port_counts}")
        print()


    # Write class mem to file
    def write(self):
        filename = os.path.dirname(self.pcap_fp)+ "/" + os.path.basename(self.pcap_fp).split(".")[0] + ".pickle"
        if os.path.exists(filename):
            os.remove(filename)
        with open(filename, 'wb') as f:
            pickle.dump(self.__dict__, f)
        print(">> Data written to file:         \t" + filename)

    # Read class mem from file
    def read(self):
        filename = os.path.dirname(self.pcap_fp)+ "/" + os.path.basename(self.pcap_fp).split(".")[0] + ".pickle"
        with open(filename, 'rb') as f:
            self.__dict__.update(pickle.load(f))
        print(">> Data read from file:          \t" + filename)

    # Write critical data to file
    def write_critical(self):
        filename = os.path.dirname(self.pcap_fp)+ "/" + os.path.basename(self.pcap_fp).split(".")[0] + "_critical.txt"
        if os.path.exists(filename):
            os.remove(filename)
        with open(filename, 'w') as f:
            for i1, i2, i3, i4, i5, i6, i7, i8, i9, i10, i11, i12, i13, i14, i15, i16, i17, i18, i19, i20, i21 in zip(
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
                self.tcp_fin_counts,
                self.tcp_src_port_counts,
                self.tcp_dst_port_counts,
                self.udp_src_port_counts,
                self.udp_dst_port_counts):
                f.write(f"{i1}\t{i2}\t{i3}\t{i4}\t{i5}\t{i6}\t{i7}\t{i8}\t{i8}\t{i9}\t{i10}\t{i11}\t{i12}\t{i13}\t{i14}\t{i15}\t{i16}\t{i17}\t{i18}\t{i19}\t{i20}\t{i21}\n")
        print(">> Critical data written to file:\t" + filename)

    # Execute multiple parsing tasks
    def exec(self):
        self.init_time = time.time()
        self.load_parse()
        print(">> Time taken for file {0}: {1:.4f} seconds".format(self.pcap_fp, time.time()-self.init_time))
        self.write_critical()
        self.write()
        #self.read()
        print(">> Execution complete\n")

    # Plot data
    def plot(self):
        print("Plotting data")

# Input data for parser class
data = {
        "data_fp": "",
        "delta_t": 10,
        "read_mode": 0, # 0: Packet stream, 1: Load into memory (make sure you have enough memory)
        "progress_display_mode": 1, # 0: by packet (waste compute resource), 1: by delta_t
        "display_critical": 1, # 1: On
        "max_packets": 0, # Extract first x packets # 0: Off
        "n_delta_t": 1, # Extract packets for first n x delta_t seconds # 0: Off
}

# Execute parser
#data["data_fp"] = "E:/GitHub/ACN_Code/hw1_traffic_pcap_parser/data/202301261400.pcap.gz"
#p1 = parser(data)
#p1.exec()
#data["data_fp"] = "E:/GitHub/ACN_Code/hw1_traffic_pcap_parser/data/202301281400.pcap.gz"
#p2 = parser(data)
#p2.exec()
data["data_fp"] = "E:/GitHub/ACN_Code/hw1_traffic_pcap_parser/data/202301301400.pcap.gz"
p3 = parser(data)
p3.exec()
#data["data_fp"] = "E:/GitHub/ACN_Code/hw1_traffic_pcap_parser/data/202301311400.pcap.gz"
#p4 = parser(data)
#p4.exec()
