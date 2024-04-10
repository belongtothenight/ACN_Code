from hCount import hCount
import numpy as np
import pandas as pd
import os
import csv
import matplotlib.pyplot as plt
import scipy.stats as stats
import time

# https://stackoverflow.com/questions/57413721/how-can-i-generate-random-variables-using-np-random-zipf-for-a-given-range-of-va
def Zipf(a: np.float64, min: np.uint64, max: np.uint64, size=None):
    """
    Generate Zipf-like random variables,
    but in inclusive [min...max] interval
    """
    if min == 0:
        raise ZeroDivisionError("")

    v = np.arange(min, max+1) # values to sample
    p = 1.0 / np.power(v, a)  # probabilities
    p /= np.sum(p)            # normalized

    return np.random.choice(v, size=size, replace=True, p=p)

def data_stream(stype, min_value, max_value, length, a=1, mu=50, sigma=10) -> np.ndarray:
    if stype == "seq":
        return np.arange(start=min_value, stop=max_value, step=1)
    elif stype == "rand":
        return np.random.randint(low=min_value, high=max_value, size=length)
    elif stype == "zipf1":
        return Zipf(a=a, min=np.uint64(1), max=np.uint64(max_value), size=length)
    elif stype == "zipf2": # overflow, error prone
        return stats.zipf(a=a).rvs(size=length).astype(np.uint64)
    elif stype == "truncnorm":
        # https://stackoverflow.com/questions/18441779/how-to-specify-upper-and-lower-limits-when-using-numpy-random-normal
        return stats.truncnorm((min_value-mu)/sigma, (max_value-mu)/sigma, loc=mu, scale=sigma).rvs(size=length).astype(np.uint64)
    else:
        raise ValueError("Invalid stream type")
