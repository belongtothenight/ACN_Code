from scapy.all import IP, TCP, PcapReader
from collections import defaultdict
import matplotlib.pyplot as plt
import time
import numpy as np
import statistics
from scipy.stats import skew, kurtosis
import math
import os
# Set the pcap file path and file names
directory_path = "E:/GitHub/ACN_Code/hw1_traffic_pcap_parser/data/"
pcap_files=['202301261400.pcap.gz']

# Define the time interval delta_T in seconds
delta_T = 10
#Entropy
import math
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
##########
# Create a dictionary to count packets and distinct IP addresses
##########
packet_count = 0
ip_packet_count =0
ip_count_src = []
ip_count_dest = []
ip_packet_counts = []
average_IATs=[]
IAT_list_deltaT=[]
IAT_list_deltaT_stds=[]
IAT_list_deltaT_skews=[]
IAT_list_deltaT_kurts=[]
sum_iat=0
ip_count_src = defaultdict(int)
ip_count_dest = defaultdict(int)

#for entropy
freq_count_src=[]
freq_count_dest=[]

ip_counts_distinct_src = []
ip_counts_distinct_dest = []
F2_srcIPs= []
F2_destIPs= []
time_stamps = []
#IPLength
average_packet_lengths = []
sum_pkt_length=0

#Protocols
ICMP_percentages=[]
TCP_percentages=[]
UDP_percentages=[]
icmp_count=0
tcp_count=0
udp_count=0
#
# Initialize TCP syn fin counters
syn_count = 0
fin_count = 0
syn_counts = []
fin_counts = []
#
entropys_srcIP=[]
entropys_destIP=[]
#
current_time = 0
previous_time= 0
start_time = 0
#
# Load the pcap files
# using PcapReader
for pp in pcap_files:
    init_time = time.time()
    # Concatenate the directory path and file name
    pcap_file = directory_path + pp
    packets = PcapReader(pcap_file)
    print("Reading file\n", pcap_file)
      
    # Loop through all packets and count the number of packets and distinct IPs for each time interval
    for packet in packets:
        if (packet_count==0):
                # Initialize the start time to the timestamp of the first packet
                # Get the first packet in the pcap file
                current_time = packet.time
                previous_time= packet.time
                start_time = packet.time
        else:
                previous_time= current_time
                current_time = packet.time
        packet_count += 1
        if IP in packet:
            ip_packet_count += 1
            ip_count_src[packet[IP].src] += 1
            ip_count_dest[packet[IP].dst] += 1
            
            iat=current_time-previous_time
            #put IAT in a list to compute std, skew and kurt
            IAT_list_deltaT.append(float(iat) )
            sum_iat=sum_iat+iat
            #the value of the len field of the IP layer. It does not contain the Ether layer (14 bytes).
            packet_length = packet[IP].len
            sum_pkt_length=sum_pkt_length+packet_length
            #Protocol
            ip_proto= packet[IP].proto
            if (ip_proto==1):
                icmp_count=icmp_count+1
            elif (ip_proto==6):
                tcp_count=tcp_count+1
            elif (ip_proto==17):
                udp_count=udp_count+1
            #
            #count TCP syn and fin packet
            if TCP in packet:
                # Check if the SYN flag is set
                if packet[TCP].flags & 0x02:
                    syn_count += 1
                # Check if the FIN flag is set
                if packet[TCP].flags & 0x01:
                    fin_count += 1
            ##
            previous_time=current_time
            #update after computing IAT 
        if ((current_time - start_time >= delta_T)):
            start_time = current_time
            #only update start time as delta_T 
            ip_packet_counts.append(ip_packet_count)
            ip_counts_distinct_src.append(len(ip_count_src))
            ip_counts_distinct_dest.append(len(ip_count_dest))
            time_stamps.append(start_time)
            #record the packet length
            #Protocols
            #Just in case the ip_count is 0 for a
            #very small observation time
            if (ip_packet_count!=0):
                average_packet_lengths.append(sum_pkt_length/ip_packet_count)
                ICMP_percentages.append(icmp_count/ip_packet_count)
                TCP_percentages.append(tcp_count/ip_packet_count)
                UDP_percentages.append(udp_count/ip_packet_count)
                # Average IAT for delta_time
                average_IATs.append(sum_iat/ip_packet_count)
            else:
                average_packet_lengths.append(0)
                ICMP_percentages.append(0)
                TCP_percentages.append(0)
                UDP_percentages.append(0)
                # Average IAT for delta_time
                average_IATs.append(0)
            #print(f"Observation time: {start_time:.6f} - {current_time:.6f}")
            #print(f"Packet count: {packet_count}")
            #print(f"Distinct IP count: {len(ip_count)}")
            #print()
            
            if (len(IAT_list_deltaT)<2):
                IAT_list_deltaT_stds.append(0)
                IAT_list_deltaT_skews.append(0)
                IAT_list_deltaT_kurts.append(0)
            else:
                IAT_list_deltaT_stds.append(statistics.variance(IAT_list_deltaT)**0.5)
                #convert decimal format into float
                IAT_floats = [float(a) for a in IAT_list_deltaT]
                IAT_list_deltaT_skews.append(skew(IAT_floats))
                IAT_list_deltaT_kurts.append(kurtosis(IAT_floats))
            
            # Calculate the second moment of the packet counts for each IP address
            # Normalized to packet_count^2
            if (ip_packet_count!=0):    
                second_freq_moment_srcIP = sum(count1**2 for count1 in ip_count_src.values())/ip_packet_count**2
                second_freq_moment_destIP = sum(count2**2 for count2 in ip_count_dest.values())/ip_packet_count**2
                F2_srcIPs.append(second_freq_moment_srcIP)
                F2_destIPs.append(second_freq_moment_destIP)
            else:
                F2_srcIPs.append(0)
                F2_destIPs.append(0)
            #Entropy
            #freq_count_src.append(freq1 for freq1 in ip_count_src.values())
            #freq_count_dest.append(freq2 for freq2 in ip_count_dest.values())
            entropys_srcIP.append(norm_entropy(ip_count_src.values()))
            entropys_destIP.append(norm_entropy(ip_count_dest.values()))
            #
            syn_counts.append(syn_count)
            fin_counts.append(fin_count)
            # Reset the counters and update the start time
            # Statistics in observation time
            ip_packet_count = 0
            sum_iat=0
            sum_pkt_length=0
            icmp_count=0
            tcp_count=0
            udp_count=0
            ip_count_src = defaultdict(int)
            ip_count_dest = defaultdict(int)
            syn_count = 0
            fin_count = 0
            
            #this IAT list is only valid for one deltaT
            IAT_list_deltaT=[]
    print("Time to process the file: ", pp, " is ", time.time() - init_time)
