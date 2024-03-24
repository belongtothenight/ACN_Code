import traffic_pcap_parser_re as tppr
import multiprocessing as mp
from multiprocessing import freeze_support
import os
import copy

def exec_index(switch_key_index, switch, switch_key, data, p):
    switch[switch_key[switch_key_index]] = 1
    p.plot(switch=switch, output_mode=1, dynamic_alpha=1)
    switch[switch_key[switch_key_index]] = 0

def exec_index2(input_data):
    switch_key_index, switch, switch_key, data, p = input_data
    switch[switch_key[switch_key_index]] = 1
    p.plot(switch=switch, output_mode=1, dynamic_alpha=1)
    switch[switch_key[switch_key_index]] = 0

def exec_single(input_data):
    switch_key, switch, data, execution_mode, process_count, parse_switch, plot_switch = input_data
    p = tppr.parser(data)
    if parse_switch == 1:
        p.exec()
    if plot_switch == 1:
        p.read()
        if execution_mode == 0:
            for i in range(len(switch_key)):
                exec_index(i, switch, switch_key, data, p)
        else:
            # Need to be careful with memory usage
            fig_count = len(switch_key)
            print(">> File: {} - Spawning pool of {} plotting processes and execute {} in parallel ...".format(os.path.basename(data["data_fp"]), fig_count, process_count), flush=True)
            input_data = [(i, switch, switch_key, data, p) for i in range(fig_count)]
            with mp.Pool(processes=process_count) as p:
                p.map(exec_index2, input_data)

if __name__ == '__main__':
    freeze_support()

    parse_switch = 1 # 0: Off, 1: On
    plot_switch = 0 # 0: Off, 1: On
    parse_execution_mode = 1 # 0: Single, 1: Multi
    parse_process_count = 4 #os.cpu_count() # Number of processes, can be adjusted, each process still need to have independent copy of data
    plot_execution_mode = 0 # 0: Single, 1: Multi # If multiple parsing processes, this should be single, or set "memory_limit to 1" (out of memory error)
    plot_process_count = 2 #os.cpu_count() # Number of processes, can be adjusted, each process still need to have independent copy of data
    memory_limit = 1 # If higher, will allow more plot_process_count, but may cause memory error
    
    # Input data for parser class
    data = {
            "data_fp": "",
            "delta_t": 10,
            "alpha": 0.5, # Plot transparency
            "dpi": 600, # Plot resolution
            "figsize": (16, 9), # Plot size
            "hide_info": 1, # 0: On, 1: Off
            "read_mode": 0, # 0: Packet stream, 1: Load into memory (make sure you have enough memory)
            "progress_display_mode": 1, # 0: by packet (waste compute resource), 1: by delta_t
            "display_critical": 0, # 1: On
            "max_packets": 0, # Extract first x packets # 0: Off
            "n_delta_t": 1, # Extract packets for first n x delta_t seconds # 0: Off
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
    paths = ["E:/GitHub/ACN_Code/hw1_traffic_pcap_parser/data/202301261400.pcap.gz",
             "E:/GitHub/ACN_Code/hw1_traffic_pcap_parser/data/202301281400.pcap.gz",
             "E:/GitHub/ACN_Code/hw1_traffic_pcap_parser/data/202301301400.pcap.gz",
             "E:/GitHub/ACN_Code/hw1_traffic_pcap_parser/data/202301311400.pcap.gz"]
    switch_key = list(switch.keys())
    
    # Display setting information
    print("=====================================================", flush=True)
    str_temp = ">> Parsing switch:\t\t{}"
    print(str_temp.format("On" if parse_switch == 1 else "Off"), flush=True)
    str_temp = ">> Plotting switch:\t\t{}"
    print(str_temp.format("On" if plot_switch == 1 else "Off"), flush=True)
    str_temp = ">> Parsing execution mode:\t{}"
    print(str_temp.format("Single" if parse_execution_mode == 0 else "Multi"), flush=True)
    str_temp = ">> Parsing process count:\t{}"
    print(str_temp.format(parse_process_count), flush=True)
    str_temp = ">> Plotting execution mode:\t{}"
    print(str_temp.format("Single" if plot_execution_mode == 0 else "Multi"), flush=True)
    str_temp = ">> Plotting process count:\t{}"
    print(str_temp.format(plot_process_count), flush=True)
    str_temp = ">> Memory limit:\t\t{}"
    print(str_temp.format(memory_limit), flush=True)
    print("=====================================================", flush=True)
    temp = data["hide_info"]
    data["data_fp"] = __file__
    data["hide_info"] = 0
    p = tppr.parser(data)
    del p
    data["hide_info"] = temp

    # Execute
    if parse_execution_mode == 0:
        for path in paths:
            data["data_fp"] = path
            input_data = (switch_key, switch, data, plot_execution_mode, plot_process_count, parse_switch, plot_switch)
            exec_single(input_data)
    else:
        if parse_process_count > memory_limit:
            plot_execution_mode = 0
        print(">> Spawning pool of {} parsing processes and execute {} in parallel ...".format(len(paths), parse_process_count), flush=True)
        input_data = []
        for path in paths:
            data["data_fp"] = path
            input_data.append((switch_key, switch, copy.deepcopy(data), plot_execution_mode, plot_process_count, parse_switch, plot_switch))
        with mp.Pool(processes=parse_process_count) as p:
            p.map(exec_single, input_data)
