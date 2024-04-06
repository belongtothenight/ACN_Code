import numpy as np
import pandas as pd
import os
import csv
import math
import copy
import time

class hCount:
    def __init__(self, window_size, delta, epsilon, max_value, hash_digit, hash_Delta=0, verbose=False):
        self.window_size = window_size
        self.delta = delta
        self.epsilon = epsilon
        self.max_value = max_value
        self.hash_digit = hash_digit
        self.hash_Delta = hash_Delta              # In percentage
        self.verbose = verbose
        # initialize
        self.hCount_star = False
        self._cal_params(delta=self.delta, epsilon=self.epsilon, M=self.max_value, hash_Delta=self.hash_Delta, verbose=self.verbose)
        self.window_cnt = 0
        self.primes = []
        self.hash_table = np.zeros((self.hash_cnt, self.hash_m), dtype=int)
        self.hash_a = np.zeros(self.hash_cnt, dtype=int)
        self.hash_b = np.zeros(self.hash_cnt, dtype=int)
        self.hash_p = 0
        self.ground_truth_dict = {}
        self._init_hash(verbose=self.verbose)
        # circular buffer
        self.window_size = window_size
        self.window_data = np.zeros(window_size, dtype=int)
        self.window_cursor = 0

    # convert delta and epsilon to data structure dimension
    def _cal_params(self, delta, epsilon, M, hash_Delta=0, verbose=False):
        self.rho = 1 - delta
        self.hash_m = round(math.e / epsilon)
        self.hash_m_default = copy.deepcopy(self.hash_m)    # m
        self.hash_m += round(self.hash_m * hash_Delta)      # m + Delta
        self.hash_cnt = round(math.log(-1 * M / math.log(self.rho)))
        if verbose:
            print("rho: {}, m: {}, k: {}".format(self.rho, self.hash_m, self.hash_cnt))

    # mode: last, random, ... (default: last)
    def _gen_prime(self, digit, mode="last", prime_cnt=1):
        def is_prime(num):
            if num == 0 or num == 1:
                return False
            for x in range(2, num):
                if num % x == 0:
                    return False
            return True
        if len(self.primes) == 0: # cache primes
            self.primes = list(filter(is_prime, range(10 ** (digit-1), 10 ** (digit))))
        if prime_cnt > 1:
            if mode == "last":
                return np.array(self.primes[-prime_cnt:])
            elif mode == "random":
                return np.random.choice(self.primes, prime_cnt, replace=True)
            else:
                return np.array(self.primes[:prime_cnt])
        else:
            if mode == "last":
                return self.primes[-1]
            elif mode == "random":
                return np.random.choice(self.primes)
            else:
                return self.primes[0]

    def _init_hash(self, verbose=False):
        digit = self.hash_digit
        if verbose:
            print("Generating hash p ...", flush=True)
        self.hash_p = self._gen_prime(digit, mode="last")
        if verbose:
            print("Generating hash a ...", flush=True)
        self.hash_a = self._gen_prime(digit, prime_cnt=self.hash_cnt, mode="random")
        if verbose:
            print("Generating hash b ...", flush=True)
        self.hash_b = self._gen_prime(digit, prime_cnt=self.hash_cnt, mode="random")

    def _hash(self, value, hash_idx):
        return int(((self.hash_a[hash_idx] * value + self.hash_b[hash_idx]) % self.hash_p) % self.hash_m)

    def _group_hash(self, value, mode_add=True):
        for i in range(self.hash_cnt):
            hash_idx = self._hash(value, i)
            #print("hash_idx: {}, type: {}".format(hash_idx, type(hash_idx)), flush=True)
            if mode_add:
                self.hash_table[i][hash_idx] += 1
            else:
                self.hash_table[i][hash_idx] -= 1

    def _insert(self, value, ground_truth=False):
        self.window_cnt += 1
        self.window_data[self.window_cursor] = value
        if ground_truth:
            #print("Adding item: {}".format(value), flush=True)
            if value in self.ground_truth_dict:
                self.ground_truth_dict[value] += 1
            else:
                self.ground_truth_dict[value] = 1
        else:
            self._group_hash(value, mode_add=True)
        self.window_cursor = (self.window_cursor + 1) % self.window_size

    def _delete(self, ground_truth=False):
        self.window_cnt -= 1
        if ground_truth:
            #print("Deleting item: {}".format(self.window_data[self.window_cursor]), flush=True)
            self.ground_truth_dict[self.window_data[self.window_cursor]] -= 1
        else:
            self._group_hash(self.window_data[self.window_cursor], mode_add=False)

    def reset_param(self):
        self.window_cursor = 0
        self.window_cnt = 0

    def hCount(self, value):
        if self.window_cnt < self.window_size:
            # window is not full
            self._insert(value)
        else:
            # window is full
            self._delete()
            self._insert(value)

    def verify(self, value):
        if self.window_cnt < self.window_size:
            # window is not full
            self._insert(value, ground_truth=True)
        else:
            # window is full
            self._delete(ground_truth=True)
            self._insert(value, ground_truth=True)

    # hCount star algorithm
    def compensate_hash_collision(self):
        self.hCount_star = True
        for i in range(self.hash_cnt):
            collision_cnt = 0
            for j in range(self.hash_m_default, self.hash_m):
                if self.hash_table[i][j] > 0:
                    collision_cnt += 1
            collision_compensation = collision_cnt / (self.hash_m - self.hash_m_default)
            self.hash_table[i] -= round(collision_compensation)
            if self.verbose:
                print("Hash table[{}]: collision_cnt: {}, collision_compensation: {}".format(i, collision_cnt, collision_compensation))

    def query_maxCount(self, value):
        value_set = []
        for i in range(self.hash_cnt):
            hash_idx = self._hash(value, i)
            #print("hash_idx: {}, type: {}".format(hash_idx, type(hash_idx)), flush=True)
            value_set.append(self.hash_table[i][hash_idx])
        return min(value_set)

    def query_all_maxCount(self, max_value):
        value_dict = {}
        for i in range(0, max_value):
            value_dict[i] = self.query_maxCount(i)
        return value_dict

    def query_eFreq(self, freq_threshold):
        if self.verbose:
            print("Querying frequent items ...")
        freq_item = []
        for i in range(0, self.max_value):
            if self.query_maxCount(i) > self.window_size * freq_threshold:
                freq_item.append(i)
                if self.verbose:
                    print("Item: {}, freq: {}".format(i, self.query_maxCount(i)/self.window_size))
        if self.verbose:
            print("Querying frequent items done.")
        return freq_item

    def query_all_eFreq(self):
        if self.verbose:
            print("Querying all frequent items ...")
        freq_dict = {}
        for i in range(0, self.max_value):
            freq_dict[i] = self.query_maxCount(i) / self.window_size
        if self.verbose:
            print("Querying all frequent items done.")
        return freq_dict

    def dump_general_params(self, params):
        if not os.path.exists("data"):
            os.makedirs("data")
        file_path = "data/hCount_general.csv"
        if os.path.exists(file_path):
            os.remove(file_path)
        with open(file_path, "w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            for key, value in params.items():
                writer.writerow([key, value])
            writer.writerow(["rho", self.rho])
            writer.writerow(["m(int)", self.hash_m_default])
            writer.writerow(["m+delta(int)", self.hash_m])
            writer.writerow(["k(int)", self.hash_cnt])
            writer.writerow(["hCount_star", self.hCount_star])

    def dump_hash_params(self):
        if not os.path.exists("data"):
            os.makedirs("data")
        file_path = "data/hCount_hash.csv"
        if os.path.exists(file_path):
            os.remove(file_path)
        df = pd.DataFrame()
        df["hash_a"] = self.hash_a
        df["hash_b"] = self.hash_b
        df["hash_p"] = self.hash_p
        df["hash_m"] = self.hash_m
        df.to_csv(file_path, index=False)
