import traffic_pcap_parser_re as tppr
import multiprocessing as mp
from multiprocessing import freeze_support
import os

def plot_index(switch_key_index, switch, switch_key, data, p):
    switch[switch_key[switch_key_index]] = 1
    p.plot(switch=switch, output_mode=1, dynamic_alpha=1, hide_info=1)
    switch[switch_key[switch_key_index]] = 0

def plot_index2(input_data):
    switch_key_index, switch, switch_key, data, p = input_data
    switch[switch_key[switch_key_index]] = 1
    p.plot(switch=switch, output_mode=1, dynamic_alpha=1, hide_info=1)
    switch[switch_key[switch_key_index]] = 0

if __name__ == '__main__':
    freeze_support()

    execution_mode = 1 # 0: Single, 1: Multi
    process_count = 2 #os.cpu_count() # Number of processes, can be adjusted, each process still need to have independent copy of data

    # Print input parameters
    print("=====================================================", flush=True)
    str_temp = ">> Execution mode:\t\t{}"
    print(str_temp.format("Single" if execution_mode == 0 else "Multi"), flush=True)
    str_temp = ">> Process count:\t\t{}"
    print(str_temp.format(process_count), flush=True)
    print("=====================================================", flush=True)
    
    # Input data for parser class
    data = {
            "data_fp": "",
            "delta_t": 10,
            "alpha": 0.5, # Plot transparency
            "dpi": 600, # Plot resolution
            "figsize": (16, 9), # Plot size
            "read_mode": 0, # 0: Packet stream, 1: Load into memory (make sure you have enough memory)
            "progress_display_mode": 1, # 0: by packet (waste compute resource), 1: by delta_t
            "display_critical": 1, # 1: On
            "max_packets": 0, # Extract first x packets # 0: Off
            "n_delta_t": 10, # Extract packets for first n x delta_t seconds # 0: Off
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
            "f12": 0, # Plot 3D x: time, y: port number, z: tcp_src_ports distribution (Giant memory required)
            "f13": 0, # Plot 3D x: time, y: port number, z: tcp_dst_ports distribution (Giant memory required)
            "f14": 0, # Plot 3D x: time, y: port number, z: udp_src_ports distribution (Giant memory required)
            "f15": 0, # Plot 3D x: time, y: port number, z: udp_dst_ports distribution (Giant memory required)
            "f16": 0, # Plot 3D x: time, y: port number, z: tcp total ports distribution
            "f17": 0, # Plot 3D x: time, y: port number, z: udp total ports distribution
            "f18": 0, # Plot 3D x: time, y: port number, z: tcp vs udp total ports distribution
            }
    switch_key = list(switch.keys())
    
    # Execute parser
    data["data_fp"] = "E:/GitHub/ACN_Code/hw1_traffic_pcap_parser/data/202301301400.pcap.gz"
    #data["data_fp"] = "/mnt/e/GitHub/ACN_Code/hw1_traffic_pcap_parser/data/202301301400.pcap.gz"
    #p3 = parser(data)
    #p3.exec()
    
    p = tppr.parser(data)
    p.read()
    if execution_mode == 0:
        for i in range(len(switch_key)):
            plot_index(i, switch, switch_key, data, p)
    else:
        # Need to be careful with memory usage
        fig_count = len(switch_key)
        print(">> Spawning pool of {} processes and execute {} in parallel ...".format(fig_count, process_count), flush=True)
        input_data = [(i, switch, switch_key, data, p) for i in range(fig_count)]
        with mp.Pool(processes=process_count) as p:
            p.map(plot_index2, input_data)
