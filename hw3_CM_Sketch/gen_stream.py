import numpy as np
import scipy

# From https://github.com/belongtothenight/ACN_Code/blob/main/hw2_hCount/data_stream.py
# a = 1
# mu = 50
# sigma = 10

def _zipf(a: np.float64, min: np.uint64, max: np.uint64, size=None):
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

def gen_seq(min_value: int, max_value: int, length: int):
    return np.arange(start=min_value, stop=max_value, step=1)

def gen_rand(min_value: int, max_value: int, length: int):
    return np.random.randint(low=min_value, high=max_value, size=length)

def gen_uniform(min_value: int, max_value: int, length: int):
    temp_data = scipy.stats.uniform().rvs(size=length)
    return (temp_data * (max_value - min_value) + min_value).astype(np.uint64)

def gen_zipf1(a: float, min_value: int, max_value: int, length: int):
    return _zipf(a, np.uint64(min_value), np.uint64(max_value), size=length)

def gen_zipf2(a: float, length: int):
    return scipy.stats.zipf(a=a).rvs(size=length).astype(np.uint64)

def gen_truncnorm(min_value: int, max_value: int, length: int, sigma: float, mu: float):
    return scipy.stats.truncnorm((min_value-mu)/sigma, (max_value-mu)/sigma, loc=mu, scale=sigma).rvs(size=length).astype(np.uint64)
