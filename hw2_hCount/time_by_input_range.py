from hCount import hCount
from data_stream import data_stream
from time_hCount import time_hCount, time_ground_truth
import numpy as np
import pandas as pd
import os
import csv
import matplotlib.pyplot as plt
import scipy.stats as stats
import time

if __name__ == "__main__":
    # Parameters
    params = {
        "data_stream_length": 100000,
        "window_size": 50000,
        "min_value": 0,     # 0, Must be 0
        "max_value": 100,   # M
        "hash_digit": 3,    # p
        "hash_Delta": 0.5,
        "epsilon": 0.01,
        "delta": 0.0001,
        "stream_type": "truncnorm", # "seq", "rand", "zipf1", "zipf2", "truncnorm"
        }
    hCount_time = []
    ground_truth_time = []
    max_value_init = 100
    max_value_step = 10
    exec_times = 100

    for i in range(exec_times):
        # Generate data stream
        params["max_value"] = max_value_init
        random_data = data_stream(stype=params["stream_type"], min_value=params["min_value"], max_value=max_value_init, length=params["data_stream_length"])

        # hCount
        hCount_time.append(time_hCount(params, random_data))

        # Ground truth count
        ground_truth_time.append(time_ground_truth(params, random_data))

        max_value_init *= max_value_step

        print("Exec time hCount/ground_truth/max_value: {:.4f}/{:.4f}/{}".format(hCount_time[-1], ground_truth_time[-1], params["max_value"]), flush=True)
