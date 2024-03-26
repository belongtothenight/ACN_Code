from scapy.all import IP, TCP, UDP, PcapReader, rdpcap
from collections import defaultdict, Counter
from scipy.stats import skew, kurtosis
from datetime import datetime
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
import matplotlib.colors as mcolors
import time
import timeit
import numpy as np
import statistics
import math
import os
import sys
import pickle
import gc

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

# array: [0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4]
# length: 5
# return: [3, 3, 3, 3, 3]
def count_array(array, length):
    counts = Counter(array)
    result = [0]*length
    for key, value in counts.items():
        result[key] = value
    return result

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
    cdef unsigned long long int hide_info
    cdef unsigned long long int dpi
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
    cdef alpha
    cdef figsize
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
        self.alpha = data["alpha"]
        self.dpi = data["dpi"]
        self.figsize = data["figsize"]
        self.hide_info = data["hide_info"]
        self.read_mode = data["read_mode"]
        self.progress_display_mode = data["progress_display_mode"]
        self.display_critical = data["display_critical"]
        self.max_packets = data["max_packets"]
        self.n_delta_t = data["n_delta_t"]
        if self.hide_info != 1:
            self.print_data()

    def print_data(self):
        self.str_temp = ">> self.pcap_fp:                {}"
        print(self.str_temp.format(self.pcap_fp), flush=True)
        self.str_temp = ">> self.delta_t:                {}"
        print(self.str_temp.format(self.delta_t), flush=True)
        self.str_temp = ">> self.alpha:                  {}"
        print(self.str_temp.format(self.alpha), flush=True)
        self.str_temp = ">> self.dpi:                    {}"
        print(self.str_temp.format(self.dpi), flush=True)
        self.str_temp = ">> self.figsize:                {}"
        print(self.str_temp.format(self.figsize), flush=True)
        self.str_temp = ">> self.read_mode:              {}"
        print(self.str_temp.format("Packet stream" if self.read_mode == 0 else "Load into memory"), flush=True)
        self.str_temp = ">> self.progress_display_mode:  {}"
        print(self.str_temp.format("By packet (more resource)" if self.progress_display_mode == 0 else "By interval/delta_t (less resource)"), flush=True)
        self.str_temp = ">> self.display_critical:       {}"
        print(self.str_temp.format("On" if self.display_critical == 1 else "Off"), flush=True)
        self.str_temp = ">> self.max_packets:            {}"
        print(self.str_temp.format("Maximum available" if self.max_packets == 0 else self.max_packets), flush=True)
        self.str_temp = ">> self.n_delta_t:              {}"
        print(self.str_temp.format("Maximum available" if self.n_delta_t == 0 else self.n_delta_t), flush=True)
        print("=============================================", flush=True)

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
        self.hide_info = 0
        self.dpi = 0
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
        self.alpha = 0.5
        self.figsize = (16, 9)
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
        print(">> Loading and parsing pcap file:\t" + self.pcap_fp, flush=True)
        if self.read_mode == 0:
            packets = PcapReader(self.pcap_fp)
        elif self.read_mode == 1:
            if self.hide_info != 1:
                print(">> Reading pcap file into memory, this may take a while...", flush=True)
                print(">> If error occurs, your system may not have enough memory to load the entire pcap file (require 40+ times space), try to split the pcap file into multiple ones; or set read_mode to 0 to read the pcap file by packet.", flush=True)
                print(">> Open Task Manager or other system monitor tools to check memory usage for main, cached, and swap memory usage.", flush=True)
            init_time = timeit.default_timer()
            packets = rdpcap(self.pcap_fp)
            print(">> Time to read pcap file: {0:.4f} seconds".format(timeit.default_timer() - init_time), flush=True)
        else:
            raise ValueError("Invalid read_mode: " + str(self.read_mode))
        if self.progress_display_mode == 0:
            full_size = os.path.getsize(self.pcap_fp)
            tmp_size = 0
        elif self.progress_display_mode == 1:
            if self.hide_info != 1:
                print(">> Progress will only be displayed when each interval is processed, please wait ...", flush=True)
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
                    print("\n>> Reached maximum packet count", flush=True)
                    break

            # Print progress
            if self.progress_display_mode == 0:
                tmp_size += len((packet.summary()).encode('utf-8'))
                print("File: {0} - Progress: {1:.4f}% - Packet Count: {2}".format(os.path.basename(self.pcap_fp), (tmp_size/full_size)*100, self.packet_count), end="\r", flush=True)

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
                    print("File: {0} - Progress: {1:.4f} seconds - Packet Count: {2} - Run Time: {3:.4f} seconds".format(os.path.basename(self.pcap_fp), (self.interval_cnt+1)*self.delta_t, self.packet_count, time.time() - self.init_time), end="\r", flush=True)
                if self.display_critical == 1:
                    self.print_critical()
                self.reset_var()
                self.interval_cnt += 1
                if self.n_delta_t != 0:
                    if self.interval_cnt >= self.n_delta_t:
                        print("\n>> Reached maximum delta_t count", flush=True)
                        break

    # Print critical data
    def print_critical(self):
        print("", flush=True)
        print(f"self.packet_count: {self.packet_count}", flush=True)
        print(f"self.timestamps: {self.timestamps}", flush=True)
        print(f"self.ip_packet_counts: {self.ip_packet_counts}", flush=True)
        print(f"self.ip_distinct_src_counts: {self.ip_distinct_src_counts}", flush=True)
        print(f"self.ip_distinct_dst_counts: {self.ip_distinct_dst_counts}", flush=True)
        print(f"self.f2_src_ips: {self.f2_src_ips}", flush=True)
        print(f"self.f2_dst_ips: {self.f2_dst_ips}", flush=True)
        print(f"self.average_iats: {self.average_iats}", flush=True)
        print(f"self.iat_delta_t_skews: {self.iat_delta_t_skews}", flush=True)
        print(f"self.iat_delta_t_kurts: {self.iat_delta_t_kurts}", flush=True)
        print(f"self.entropy_src_ips: {self.entropy_src_ips}", flush=True)
        print(f"self.entropy_dst_ips: {self.entropy_dst_ips}", flush=True)
        print(f"self.average_packet_lengths: {self.average_packet_lengths}", flush=True)
        print(f"self.icmp_percentages: {self.icmp_percentages}", flush=True)
        print(f"self.tcp_percentages: {self.tcp_percentages}", flush=True)
        print(f"self.udp_percentages: {self.udp_percentages}", flush=True)
        print(f"self.tcp_syn_counts: {self.tcp_syn_counts}", flush=True)
        print(f"self.tcp_fin_counts: {self.tcp_fin_counts}", flush=True)
        print(f"len(self.tcp_src_port_distinct): {len(self.tcp_src_port_distinct)}", flush=True)
        print(f"len(self.tcp_dst_port_distinct): {len(self.tcp_dst_port_distinct)}", flush=True)
        print(f"len(self.udp_src_port_distinct): {len(self.udp_src_port_distinct)}", flush=True)
        print(f"len(self.udp_dst_port_distinct): {len(self.udp_dst_port_distinct)}", flush=True)
        print(f"self.tcp_src_port_counts: {self.tcp_src_port_counts}", flush=True)
        print("", flush=True)


    # Write class mem to file (cython not supported)
    def write(self):
        dirname = os.path.join(os.path.dirname(__file__), "mem_dump")
        if not os.path.exists(dirname):
            os.makedirs(dirname)
        filename = os.path.join(dirname, os.path.basename(self.pcap_fp).split(".")[0] + ".pickle")
        if os.path.exists(filename):
            os.remove(filename)
        with open(filename, 'wb') as f:
            pickle.dump(self.__dict__, f)
        print(">> Data written to file:         \t" + filename, flush=True)

    # Read class mem from file
    def read(self):
        dirname = os.path.join(os.path.dirname(__file__), "mem_dump")
        filename = os.path.join(dirname, os.path.basename(self.pcap_fp).split(".")[0] + ".pickle")
        print(">> Reading data from {} ..." .format(filename), flush=True)
        with open(filename, 'rb') as f:
            temp = pickle.load(f)
            # Port latest setting
            temp["n_delta_t"] = self.n_delta_t
            temp["dpi"] = self.dpi
            temp["figsize"] = self.figsize
            temp["alpha"] = self.alpha
            temp["hide_info"] = self.hide_info
            self.__dict__.update(temp)
        print(">> Data read from file:          \t" + filename, flush=True)

    # Write critical data to file
    def write_critical(self):
        dirname = os.path.join(os.path.dirname(__file__), "critical")
        if not os.path.exists(dirname):
            os.makedirs(dirname)
        filename = os.path.join(dirname, os.path.basename(self.pcap_fp).split(".")[0] + "_critical.txt")
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
        print(">> Critical data written to file:\t" + filename, flush=True)

    # Write port count to file
    def write_port_count(self):
        dirname = os.path.join(os.path.dirname(__file__), "port_count")
        if not os.path.exists(dirname):
            os.makedirs(dirname)
        filename = os.path.join(dirname, os.path.basename(self.pcap_fp).split(".")[0] + "_port_count.txt")
        if os.path.exists(filename):
            os.remove(filename)
        with open(filename, 'w') as f:
            f.write("List of distinct port counts in {} intervals\n".format(self.n_delta_t))
            f.write("TCP SRC:\t{}\n".format(len(self.tcp_src_port_distinct)))
            f.write("TCP DST:\t{}\n".format(len(self.tcp_dst_port_distinct)))
            f.write("UDP SRC:\t{}\n".format(len(self.udp_src_port_distinct)))
            f.write("UDP DST:\t{}\n".format(len(self.udp_dst_port_distinct)))
            f.write("Total:\t\t{}\n".format(len(self.tcp_src_port_distinct) + len(self.tcp_dst_port_distinct) + len(self.udp_src_port_distinct) + len(self.udp_dst_port_distinct)))
        print(">> Port count written to file:\t\t" + filename, flush=True)

    # Execute multiple parsing tasks
    def exec(self):
        self.init_time = time.time()
        self.load_parse()
        print(">> Time taken for file {0}: {1:.4f} seconds".format(self.pcap_fp, time.time()-self.init_time), flush=True)
        self.write()
        print(">> Execution complete\n", flush=True)

    # Plot data
    def plot(self, switch, output_mode=0, dynamic_alpha=0, min_alpha=0.2):
        # output_mode 0: show plot, 1: save plot
        # dynamic_alpha 0: static, 1: dynamic (slow) (only for 3D bar plots)
        # hide_info 0: show info, 1: hide info
        def save_plot(fig, filename, hide_info=0):
            if hide_info != 1:
                print(">> Saving plot to file ...", flush=True)
            dirname = os.path.join(os.path.dirname(__file__), "plot")
            if not os.path.exists(dirname):
                os.makedirs(dirname)
            filename = os.path.join(dirname, os.path.basename(self.pcap_fp).split(".")[0] + "_" + filename + ".png")
            fig.savefig(filename, dpi=self.dpi)
            print(">> Plot saved to file:           \t" + filename, flush=True)
            plt.close(fig)
            gc.collect()
        def plot_ax(ax, x, y, bottom, width, depth, top, shade, alpha, color, dynamic_alpha=0, min_alpha=0.2):
            # Coloring: https://stackoverflow.com/questions/42086276/get-default-line-color-cycle
            #           https://stackoverflow.com/questions/24767355/individual-alpha-values-in-scatter-plot
            if dynamic_alpha == 0:
                ax.bar3d(x, y, bottom, width, depth, top, shade=shade, alpha=alpha)
            elif dynamic_alpha == 1:
                max_top = top.max()
                alpha_temp = top/max_top*alpha
                alpha_temp[alpha_temp < min_alpha] = min_alpha
                rgba_colors = np.zeros((len(x), 4))
                rgba_colors[:, 0] = mcolors.to_rgba(color)[0]
                rgba_colors[:, 1] = mcolors.to_rgba(color)[1]
                rgba_colors[:, 2] = mcolors.to_rgba(color)[2]
                rgba_colors[:, 3] = alpha_temp
                ax.bar3d(x, y, bottom, width, depth, top, shade=shade, color=rgba_colors)
                #for i in range(len(x)):
                    #ax.bar3d(x[i], y[i], bottom[i], width, depth, top[i], shade=shade, alpha=alpha_temp[i], color=color)
            else:
                print(">> Invalid dynamic_alpha value", flush=True)
                sys.exit(1)
            return ax
        if self.n_delta_t != 0:
            self.interval_cnt = self.n_delta_t
        if self.hide_info != 1:
            print("=============================================", flush=True)
            self.str_temp = ">> Selected interval count:     {}"
            print(self.str_temp.format(self.n_delta_t), flush=True)
            self.str_temp = ">> Mode:                        {}"
            print(self.str_temp.format("Show plot" if output_mode == 0 else "Save plot"), flush=True)
            self.str_temp = ">> Dynamic alpha:               {}"
            print(self.str_temp.format("Enabled (slow)" if dynamic_alpha == 1 else "Disabled"), flush=True)
            print("=============================================", flush=True)
        times = [datetime.fromtimestamp(float(sec)) for sec in self.timestamps]
        colors = plt.rcParams['axes.prop_cycle'].by_key()['color']
        # [+]  Plot the packet count using matplotlib
        if switch["f1"] == 1:
            print(">> Plotting figure 1", flush=True)
            f1 = plt.figure(1, figsize=self.figsize)
            plt.xlabel('Time (s)')
            plt.ylabel('Count')
            plt.title('Packet Count over Time (interval: {})'.format(self.interval_cnt))
            plt.xticks(rotation=45)  # Rotate x-axis labels for better visibility
            plt.plot(times[:self.interval_cnt], self.ip_packet_counts[:self.interval_cnt], label='Packet Count',marker=".")
            plt.legend()
            if output_mode == 1: save_plot(f1, "1", self.hide_info)
            else: plt.show()
        # [+]  Plot the source IP count using matplotlib
        if switch["f2"] == 1:
            print(">> Plotting figure 2", flush=True)
            f2 = plt.figure(2, figsize=self.figsize)
            plt.xlabel('Time (s)')
            plt.ylabel('Count')
            plt.title('Distinct Source & Dest IP Count over Time (interval: {})'.format(self.interval_cnt))
            plt.xticks(rotation=45)  # Rotate x-axis labels for better visibility
            plt.plot(times[:self.interval_cnt], self.ip_distinct_dst_counts[:self.interval_cnt], label='Distinct Destination IP Count',marker=".")
            plt.plot(times[:self.interval_cnt], self.ip_distinct_src_counts[:self.interval_cnt], label='Distinct Source IP Count',marker=".")
            plt.legend()
            if output_mode == 1: save_plot(f2, "2", self.hide_info)
            else: plt.show()
        # [+] Plot F2 of Src and Dest IPs
        if switch["f3"] == 1:
            print(">> Plotting figure 3", flush=True)
            f3 = plt.figure(3, figsize=self.figsize)
            plt.xlabel('Time (s)')
            plt.ylabel('Count')
            plt.title('F2 of Src & Dest IP Count over Time (interval: {})'.format(self.interval_cnt))
            plt.xticks(rotation=45)  # Rotate x-axis labels for better visibility
            plt.plot(times[:self.interval_cnt], self.f2_dst_ips[:self.interval_cnt], label='F2 Destination IP Count',marker=".")
            plt.plot(times[:self.interval_cnt], self.f2_src_ips[:self.interval_cnt], label='F2 Source IP Count',marker=".")
            plt.legend()
            if output_mode == 1: save_plot(f3, "3", self.hide_info)
            else: plt.show()
        # [+] Plot average IAT
        if switch["f4"] == 1:
            print(">> Plotting figure 4", flush=True)
            f4 = plt.figure(4, figsize=self.figsize)
            plt.xlabel('Time (s)')
            plt.ylabel('Sec')
            plt.title('Average IAT over Time (interval: {})'.format(self.interval_cnt))
            plt.xticks(rotation=45)  # Rotate x-axis labels for better visibility
            plt.plot(times[:self.interval_cnt], self.average_iats[:self.interval_cnt], label='Average IAT',marker=".")
            plt.legend()
            if output_mode == 1: save_plot(f4, "4", self.hide_info)
            else: plt.show()
        # [+] Plot Average packet length
        if switch["f5"] == 1:
            print(">> Plotting figure 5", flush=True)
            f5 = plt.figure(5, figsize=self.figsize)
            plt.xlabel('Sec')
            plt.ylabel('Bytes')
            plt.title('Average PKT Length over Time (interval: {})'.format(self.interval_cnt))
            plt.xticks(rotation=45)  # Rotate x-axis labels for better visibility
            plt.plot(times[:self.interval_cnt], self.average_packet_lengths[:self.interval_cnt], label='Average PKT Length',marker=".")
            plt.legend()
            if output_mode == 1: save_plot(f5, "5", self.hide_info)
            else: plt.show()
        # [+] Plot Protocol Percentage
        if switch["f6"] == 1:
            print(">> Plotting figure 6", flush=True)
            f6 = plt.figure(6, figsize=self.figsize)
            plt.xlabel('Sec')
            plt.ylabel('%')
            plt.title('Protocol Percentage over Time (interval: {})'.format(self.interval_cnt))
            plt.xticks(rotation=45)  # Rotate x-axis labels for better visibility
            plt.plot(times[:self.interval_cnt], self.icmp_percentages[:self.interval_cnt], label='ICMP',marker=".")
            plt.plot(times[:self.interval_cnt], self.tcp_percentages[:self.interval_cnt], label='TCP',marker=".")
            plt.plot(times[:self.interval_cnt], self.udp_percentages[:self.interval_cnt], label='UDP',marker=".")
            plt.legend()
            if output_mode == 1: save_plot(f6, "6", self.hide_info)
            else: plt.show()
        # [+] Plot Syn FIN
        if switch["f7"] == 1:
            print(">> Plotting figure 7", flush=True)
            f7 = plt.figure(7, figsize=self.figsize)
            plt.xlabel('Sec')
            plt.ylabel('Packet Count')
            plt.title('SYN & FIN over Time (interval: {})'.format(self.interval_cnt))
            plt.xticks(rotation=45)  # Rotate x-axis labels for better visibility
            plt.plot(times[:self.interval_cnt], self.tcp_syn_counts[:self.interval_cnt], label='SYN',marker=".")
            plt.plot(times[:self.interval_cnt], self.tcp_fin_counts[:self.interval_cnt], label='FIN',marker=".")
            plt.legend()
            if output_mode == 1: save_plot(f7, "7", self.hide_info)
            else: plt.show()
        # [+] Plot average IAT mean, stdv
        if switch["f8"] == 1:
            #print(">> Plotting figure 8", flush=True)
            #f8 = plt.figure(8, figsize=self.figsize)
            #plt.xlabel('Time (s)')
            #plt.ylabel('Sec')
            #plt.title('Average IAT over Time (interval: {})'.format(self.interval_cnt))
            #plt.xticks(rotation=45)  # Rotate x-axis labels for better visibility
            #plt.errorbar(time_stamps, average_IATs, IAT_list_deltaT_stds, linestyle='None', marker='^')
            #plt.legend()
            #if output_mode == 1: save_plot(f8, "8", self.hide_info)
            #else: plt.show()
            print(">> Plot 8 is disabled", flush=True)
        # [+] Plot average IAT skew 
        if switch["f9"] == 1:
            print(">> Plotting figure 9", flush=True)
            f9 = plt.figure(9, figsize=self.figsize)
            plt.xlabel('Time (s)')
            plt.ylabel('IAT Skew')
            plt.title('IAT Skew over Time (interval: {})'.format(self.interval_cnt))
            plt.xticks(rotation=45)  # Rotate x-axis labels for better visibility
            plt.plot(times[:self.interval_cnt], self.iat_delta_t_skews[:self.interval_cnt], label='Skew',marker=".")
            plt.legend()
            if output_mode == 1: save_plot(f9, "9", self.hide_info)
            else: plt.show()
        # [+] Plot average IAT Kurt
        if switch["f10"] == 1:
            print(">> Plotting figure 10", flush=True)
            f10 = plt.figure(10, figsize=self.figsize)
            plt.xlabel('Time (s)')
            plt.title('IAT Kurts over Time (interval: {})'.format(self.interval_cnt))
            plt.xticks(rotation=45)  # Rotate x-axis labels for better visibility
            plt.plot(times[:self.interval_cnt], self.iat_delta_t_kurts[:self.interval_cnt], label='Kurts',marker=".")
            plt.legend()
            if output_mode == 1: save_plot(f10, "10", self.hide_info)
            else: plt.show()
        # [+] Plot Entropy
        if switch["f11"] == 1:
            print(">> Plotting figure 11", flush=True)
            f11 = plt.figure(11, figsize=self.figsize)
            plt.xlabel('Time (s)')
            plt.ylabel('Entropy')
            plt.title('Normalized Entropy over Time (interval: {})'.format(self.interval_cnt))
            plt.xticks(rotation=45)  # Rotate x-axis labels for better visibility
            plt.plot(times[:self.interval_cnt], self.entropy_src_ips[:self.interval_cnt], label='Source IP',marker=".")
            plt.plot(times[:self.interval_cnt], self.entropy_dst_ips[:self.interval_cnt], label='Destnation IP',marker=".")
            plt.legend()
            if output_mode == 1: save_plot(f11, "11", self.hide_info)
            else: plt.show()
        # [+] Plot 3D x: time, y: port number, z: tcp_src_ports distribution (can't use time as x-axis, so use interval number instead)
        if switch["f12"] == 1:
            print(">> Plotting figure 12 (takes longer time ...)", flush=True)
            f12 = plt.figure(12, figsize=self.figsize)
            port_max = 65536
            temp_list = [0] * self.interval_cnt
            for i in range(self.interval_cnt):
                temp_list[i] = count_array(self.tcp_src_ports[i], port_max)
            ax = f12.add_subplot(111, projection='3d')
            ax.set_xlabel('Interval')
            ax.set_ylabel('Port')
            ax.set_zlabel('Count / Total Count')
            if dynamic_alpha == 1:
                ax.set_title('3D TCP Source Port Distribution (interval: {}, max_alpha: {}, min_alpha: {})'.format(self.interval_cnt, self.alpha, min_alpha))
            else:
                ax.set_title('3D TCP Source Port Distribution (interval: {}, alpha: {})'.format(self.interval_cnt, self.alpha))
                min_alpha = self.alpha
            x = np.arange(0, self.interval_cnt)
            y = np.arange(port_max)
            _x, _y = np.meshgrid(x, y)
            x, y = _x.ravel(), _y.ravel()
            top = np.array(temp_list).ravel() / self.packet_count
            bottom = np.zeros_like(top)
            width = depth = 1
            plot_ax(ax, x, y, bottom, width, depth, top, True, self.alpha, colors[0], dynamic_alpha, min_alpha)
            if output_mode == 1: save_plot(f12, "12", self.hide_info)
            else: plt.show()
        # [+] Plot 3D x: time, y: port number, z: tcp_dst_ports distribution (can't use time as x-axis, so use interval number instead)
        if switch["f13"] == 1:
            print(">> Plotting figure 13 (takes longer time ...)", flush=True)
            f13 = plt.figure(13, figsize=self.figsize)
            port_max = 65536
            temp_list = [0] * self.interval_cnt
            for i in range(self.interval_cnt):
                temp_list[i] = count_array(self.tcp_dst_ports[i], port_max)
            ax = f13.add_subplot(111, projection='3d')
            ax.set_xlabel('Interval')
            ax.set_ylabel('Port')
            ax.set_zlabel('Count / Total Count')
            if dynamic_alpha == 1:
                ax.set_title('3D TCP Destination Port Distribution (interval: {}, max_alpha: {}, min_alpha: {})'.format(self.interval_cnt, self.alpha, min_alpha))
            else:
                ax.set_title('3D TCP Destination Port Distribution (interval: {}, alpha: {})'.format(self.interval_cnt, self.alpha))
                min_alpha = self.alpha
            x = np.arange(0, self.interval_cnt)
            y = np.arange(port_max)
            _x, _y = np.meshgrid(x, y)
            x, y = _x.ravel(), _y.ravel()
            top = np.array(temp_list).ravel() / self.packet_count
            bottom = np.zeros_like(top)
            width = depth = 1
            plot_ax(ax, x, y, bottom, width, depth, top, True, self.alpha, colors[0], dynamic_alpha, min_alpha)
            if output_mode == 1: save_plot(f13, "13", self.hide_info)
            else: plt.show()
        # [+] Plot 3D x: time, y: port number, z: udp_src_ports distribution (can't use time as x-axis, so use interval number instead)
        if switch["f14"] == 1:
            print(">> Plotting figure 14 (takes longer time ...)", flush=True)
            f14 = plt.figure(14, figsize=self.figsize)
            port_max = 65536
            temp_list = [0] * self.interval_cnt
            for i in range(self.interval_cnt):
                temp_list[i] = count_array(self.udp_src_ports[i], port_max)
            ax = f14.add_subplot(111, projection='3d')
            ax.set_xlabel('Interval')
            ax.set_ylabel('Port')
            ax.set_zlabel('Count / Total Count')
            if dynamic_alpha == 1:
                ax.set_title('3D UDP Source Port Distribution (interval: {}, max_alpha: {}, min_alpha: {})'.format(self.interval_cnt, self.alpha, min_alpha))
            else:
                ax.set_title('3D UDP Source Port Distribution (interval: {}, alpha: {})'.format(self.interval_cnt, self.alpha))
                min_alpha = self.alpha
            x = np.arange(0, self.interval_cnt)
            y = np.arange(port_max)
            _x, _y = np.meshgrid(x, y)
            x, y = _x.ravel(), _y.ravel()
            top = np.array(temp_list).ravel() / self.packet_count
            bottom = np.zeros_like(top)
            width = depth = 1
            plot_ax(ax, x, y, bottom, width, depth, top, True, self.alpha, colors[0], dynamic_alpha, min_alpha)
            if output_mode == 1: save_plot(f14, "14", self.hide_info)
            else: plt.show()
        # [+] Plot 3D x: time, y: port number, z: udp_dst_ports distribution (can't use time as x-axis, so use interval number instead)
        if switch["f15"] == 1:
            print(">> Plotting figure 15 (takes longer time ...)", flush=True)
            f15 = plt.figure(15, figsize=self.figsize)
            port_max = 65536
            temp_list = [0] * self.interval_cnt
            for i in range(self.interval_cnt):
                temp_list[i] = count_array(self.udp_dst_ports[i], port_max)
            ax = f15.add_subplot(111, projection='3d')
            ax.set_xlabel('Interval')
            ax.set_ylabel('Port')
            ax.set_zlabel('Count / Total Count')
            if dynamic_alpha == 1:
                ax.set_title('3D UDP Destination Port Distribution (interval: {}, max_alpha: {}, min_alpha: {})'.format(self.interval_cnt, self.alpha, min_alpha))
            else:
                ax.set_title('3D UDP Destination Port Distribution (interval: {}, alpha: {})'.format(self.interval_cnt, self.alpha))
                min_alpha = self.alpha
            x = np.arange(0, self.interval_cnt)
            y = np.arange(port_max)
            _x, _y = np.meshgrid(x, y)
            x, y = _x.ravel(), _y.ravel()
            top = np.array(temp_list).ravel() / self.packet_count
            bottom = np.zeros_like(top)
            width = depth = 1
            plot_ax(ax, x, y, bottom, width, depth, top, True, self.alpha, colors[0], dynamic_alpha, min_alpha)
            if output_mode == 1: save_plot(f15, "15", self.hide_info)
            else: plt.show()
        # [+] Plot 3D x: time, y: port number, z: tcp total ports distribution (can't use time as x-axis, so use interval number instead)
        if switch["f16"] == 1:
            print(">> Plotting figure 16 (takes longer time ...)", flush=True)
            f16 = plt.figure(16, figsize=self.figsize)
            port_max = 65536
            ax = f16.add_subplot(111, projection='3d')
            ax.set_xlabel('Interval')
            ax.set_ylabel('Port')
            ax.set_zlabel('Count / Total Count')
            if dynamic_alpha == 1:
                ax.set_title('3D TCP Total Port Distribution (interval: {}, max_alpha: {}, min_alpha: {})'.format(self.interval_cnt, self.alpha, min_alpha))
            else:
                ax.set_title('3D TCP Total Port Distribution (interval: {}, alpha: {})'.format(self.interval_cnt, self.alpha))
                min_alpha = self.alpha
            x = np.arange(0, self.interval_cnt)
            y = np.arange(port_max)
            _x, _y = np.meshgrid(x, y)
            x, y = _x.ravel(), _y.ravel()
            width = depth = 1
            temp_list = [0] * self.interval_cnt
            # src
            for i in range(self.interval_cnt):
                temp_list[i] = count_array(self.tcp_src_ports[i], port_max)
            top = np.array(temp_list).ravel() / self.packet_count
            bottom = np.zeros_like(top)
            plot_ax(ax, x, y, bottom, width, depth, top, True, self.alpha, colors[0], dynamic_alpha, min_alpha)
            # dst
            for i in range(self.interval_cnt):
                temp_list[i] = count_array(self.tcp_dst_ports[i], port_max)
            top = np.array(temp_list).ravel() / self.packet_count
            bottom = np.zeros_like(top)
            plot_ax(ax, x, y, bottom, width, depth, top, True, self.alpha, colors[1], dynamic_alpha, min_alpha)
            ax.legend(["Source {}".format(colors[0]), "Destination {}".format(colors[1])])
            if output_mode == 1: save_plot(f16, "16", self.hide_info)
            else: plt.show()
        # [+] Plot 3D x: time, y: port number, z: udp total ports distribution (can't use time as x-axis, so use interval number instead)
        if switch["f17"] == 1:
            print(">> Plotting figure 17 (takes longer time ...)", flush=True)
            f17 = plt.figure(17, figsize=self.figsize)
            port_max = 65536
            ax = f17.add_subplot(111, projection='3d')
            ax.set_xlabel('Interval')
            ax.set_ylabel('Port')
            ax.set_zlabel('Count / Total Count')
            if dynamic_alpha == 1:
                ax.set_title('3D UDP Total Port Distribution (interval: {}, max_alpha: {}, min_alpha: {})'.format(self.interval_cnt, self.alpha, min_alpha))
            else:
                ax.set_title('3D UDP Total Port Distribution (interval: {}, alpha: {})'.format(self.interval_cnt, self.alpha))
                min_alpha = self.alpha
            x = np.arange(0, self.interval_cnt)
            y = np.arange(port_max)
            _x, _y = np.meshgrid(x, y)
            x, y = _x.ravel(), _y.ravel()
            width = depth = 1
            temp_list = [0] * self.interval_cnt
            # src
            for i in range(self.interval_cnt):
                temp_list[i] = count_array(self.udp_src_ports[i], port_max)
            top = np.array(temp_list).ravel() / self.packet_count
            bottom = np.zeros_like(top)
            plot_ax(ax, x, y, bottom, width, depth, top, True, self.alpha, colors[0], dynamic_alpha, min_alpha)
            # dst
            for i in range(self.interval_cnt):
                temp_list[i] = count_array(self.udp_dst_ports[i], port_max)
            top = np.array(temp_list).ravel() / self.packet_count
            bottom = np.zeros_like(top)
            plot_ax(ax, x, y, bottom, width, depth, top, True, self.alpha, colors[1], dynamic_alpha, min_alpha)
            ax.legend(["Source {}".format(colors[0]), "Destination {}".format(colors[1])])
            if output_mode == 1: save_plot(f17, "17", self.hide_info)
            else: plt.show()
        # [+] Plot 3D x: time, y: port number, z: total ports distribution (can't use time as x-axis, so use interval number instead) (tcp vs. udp)
        if switch["f18"] == 1:
            print(">> Plotting figure 18 (takes longer time ...)", flush=True)
            f18 = plt.figure(18, figsize=self.figsize)
            port_max = 65536
            ax = f18.add_subplot(111, projection='3d')
            ax.set_xlabel('Interval')
            ax.set_ylabel('Port')
            ax.set_zlabel('Count / Total Count')
            if dynamic_alpha == 1:
                ax.set_title('3D Total Port Distribution (interval: {}, max_alpha: {}, min_alpha: {})'.format(self.interval_cnt, self.alpha, min_alpha))
            else:
                ax.set_title('3D Total Port Distribution (interval: {}, alpha: {})'.format(self.interval_cnt, self.alpha))
                min_alpha = self.alpha
            x = np.arange(0, self.interval_cnt)
            y = np.arange(port_max)
            _x, _y = np.meshgrid(x, y)
            x, y = _x.ravel(), _y.ravel()
            width = depth = 1
            temp_list = [0] * self.interval_cnt
            # tcp
            for i in range(self.interval_cnt):
                temp_list[i] = count_array(self.tcp_src_ports[i], port_max)
            top = np.array(temp_list).ravel() / self.packet_count
            bottom = np.zeros_like(top)
            plot_ax(ax, x, y, bottom, width, depth, top, True, self.alpha, colors[0], dynamic_alpha, min_alpha)
            for i in range(self.interval_cnt):
                temp_list[i] = count_array(self.tcp_dst_ports[i], port_max)
            top = np.array(temp_list).ravel() / self.packet_count
            bottom = np.zeros_like(top)
            plot_ax(ax, x, y, bottom, width, depth, top, True, self.alpha, colors[1], dynamic_alpha, min_alpha)
            # udp
            for i in range(self.interval_cnt):
                temp_list[i] = count_array(self.udp_src_ports[i], port_max)
            top = np.array(temp_list).ravel() / self.packet_count
            bottom = np.zeros_like(top)
            plot_ax(ax, x, y, bottom, width, depth, top, True, self.alpha, colors[2], dynamic_alpha, min_alpha)
            for i in range(self.interval_cnt):
                temp_list[i] = count_array(self.udp_dst_ports[i], port_max)
            top = np.array(temp_list).ravel() / self.packet_count
            bottom = np.zeros_like(top)
            plot_ax(ax, x, y, bottom, width, depth, top, True, self.alpha, colors[3], dynamic_alpha, min_alpha)
            ax.legend(["TCP Source {}".format(colors[0]), "TCP Destination {}".format(colors[1]), "UDP Source {}".format(colors[2]), "UDP Destination {}".format(colors[3])])
            if output_mode == 1: save_plot(f18, "18", self.hide_info)
            else: plt.show()

        if self.hide_info != 1:
            if output_mode == 1:
                print(">> Plots saved", flush=True)
            elif output_mode == 0:
                print(">> Plots displayed", flush=True)
            else:
                print(">> Invalid output_mode", flush=True)

if __name__ == "__main__":
    # Input data for parser class
    data = {
            "data_fp": "",
            "delta_t": 10,
            "alpha": 0.5, # Plot transparency
            "dpi": 600, # Plot resolution
            "figsize": (16, 9), # Plot size
            "hide_info": 0, # 0: Show info, 1: Hide info
            "read_mode": 0, # 0: Packet stream, 1: Load into memory (make sure you have enough memory)
            "progress_display_mode": 1, # 0: by packet (waste compute resource), 1: by delta_t
            "display_critical": 1, # 1: On
            "max_packets": 0, # Extract first x packets # 0: Off
            "n_delta_t": 0, # Extract packets for first n x delta_t seconds # 0: Off
    }
    # Input switch for parser.plot
    switch = {
            "f1": 0, # Plot Packet Count
            "f2": 0, # Plot src & dst IP count
            "f3": 0, # Plot f2 of src & dst IP count
            "f4": 0, # Plot average IAT
            "f5": 0, # Plot average packet length
            "f6": 0, # Plot Protocol Percentage
            "f7": 0, # Plot Syn Fin
            "f8": 0, # Plot average IAT mean, stdv (not finished yet)
            "f9": 0, # Plot average IAT skew
            "f10": 0, # Plot average IAT Kurt
            "f11": 0, # Plot Entropy
            "f12": 1, # Plot 3D x: time, y: port number, z: tcp_src_ports distribution (Giant memory required)
            "f13": 0, # Plot 3D x: time, y: port number, z: tcp_dst_ports distribution (Giant memory required)
            "f14": 0, # Plot 3D x: time, y: port number, z: udp_src_ports distribution (Giant memory required)
            "f15": 0, # Plot 3D x: time, y: port number, z: udp_dst_ports distribution (Giant memory required)
            "f16": 0, # Plot 3D x: time, y: port number, z: tcp total ports distribution
            "f17": 0, # Plot 3D x: time, y: port number, z: udp total ports distribution
            "f18": 0, # Plot 3D x: time, y: port number, z: tcp vs udp total ports distribution
            }
    
    # Execute parser
    #data["data_fp"] = "E:/GitHub/ACN_Code/hw1_traffic_pcap_parser/data/202301261400.pcap.gz"
    #p1 = parser(data)
    #p1.exec()
    #data["data_fp"] = "E:/GitHub/ACN_Code/hw1_traffic_pcap_parser/data/202301281400.pcap.gz"
    #p2 = parser(data)
    #p2.exec()
    data["data_fp"] = "E:/GitHub/ACN_Code/hw1_traffic_pcap_parser/data/202301301400.pcap.gz"
    #data["data_fp"] = "/mnt/e/GitHub/ACN_Code/hw1_traffic_pcap_parser/data/202301301400.pcap.gz"
    #p3 = parser(data)
    #p3.exec()
    #data["data_fp"] = "E:/GitHub/ACN_Code/hw1_traffic_pcap_parser/data/202301311400.pcap.gz"
    #p4 = parser(data)
    #p4.exec()

    # Plot data
    p = parser(data)
    p.read()
    p.write_critical()
    p.write_port_count()
    p.plot(switch=switch, output_mode=1, dynamic_alpha=1)
