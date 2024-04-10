from hCount import hCount
import numpy as np
import time

def time_hCount(params: dict, data_stream: np.ndarray) -> float:
    hc = hCount(window_size=params["window_size"], delta=params["delta"], epsilon=params["epsilon"], max_value=params["max_value"], hash_digit=params["hash_digit"], hash_Delta=params["hash_Delta"], verbose=False)
    start_time = time.time()
    for i in range(params["data_stream_length"]):
        hc.hCount(data_stream[i])
    return time.time()-start_time

def time_ground_truth(params: dict, data_stream: np.ndarray) -> float:
    hc = hCount(window_size=params["window_size"], delta=params["delta"], epsilon=params["epsilon"], max_value=params["max_value"], hash_digit=params["hash_digit"], hash_Delta=params["hash_Delta"], verbose=False)
    start_time = time.time()
    for i in range(params["data_stream_length"]):
        hc.ground_truth(data_stream[i])
    return time.time()-start_time
