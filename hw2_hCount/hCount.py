import numpy as np
import time

class hCount:
    def __init__(self, window_size, hash_cnt, m):
        # paper parameter
        self.window_size = window_size
        self.hash_cnt = hash_cnt # k
        self.window_cnt = 0 # N
        self.hash_table = np.zeros((hash_cnt, m), dtype=int)
        self.hash_a = np.zeros(hash_cnt, dtype=int)
        self.hash_b = np.zeros(hash_cnt, dtype=int)
        self.hash_p = 0
        self.hash_m = m
        self.ground_truth_dict = {}
        # circular buffer
        self.window_size = window_size
        self.window_data = np.zeros(window_size, dtype=int)
        self.window_cursor = 0

    def _reset_param(self):
        self.window_cursor = 0
        self.window_cnt = 0

    # mode: last, random, ... (default: last)
    def _gen_prime(self, digit, mode="last", prime_cnt=1):
        def is_prime(num):
            if num == 0 or num == 1:
                return False
            for x in range(2, num):
                if num % x == 0:
                    return False
            return True
        data = list(filter(is_prime, range(10 ** (digit-1), 10 ** (digit))))
        if prime_cnt > 1:
            if mode == "last":
                return np.array(data[-prime_cnt:])
            elif mode == "random":
                return np.random.choice(data, prime_cnt, replace=False)
            else:
                return np.array(data[:prime_cnt])
        else:
            if mode == "last":
                return data[-1]
            elif mode == "random":
                return np.random.choice(data)
            else:
                return data[0]

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
        if ground_truth:
            #print("Adding item: {}".format(value), flush=True)
            if value in self.ground_truth_dict:
                self.ground_truth_dict[value] += 1
            else:
                self.ground_truth_dict[value] = 1
        else:
            self.window_cnt += 1
            self.window_data[self.window_cursor] = value
            self._group_hash(value, mode_add=True)
            self.window_cursor = (self.window_cursor + 1) % self.window_size

    def _delete(self, ground_truth=False):
        if ground_truth:
            #print("Deleting item: {}".format(self.window_data[self.window_cursor]), flush=True)
            self.ground_truth_dict[self.window_data[self.window_cursor]] -= 1
        else:
            self.window_cnt -= 1
            self._group_hash(self.window_data[self.window_cursor], mode_add=False)

    def _compensate_hash_collision(self):
        pass

    def init_hash(self, p_digit=10, a_digit=5, b_digit=5):
        self.hash_p = self._gen_prime(p_digit, mode="last")
        self.hash_a = self._gen_prime(a_digit, prime_cnt=self.hash_cnt, mode="random")
        self.hash_b = self._gen_prime(b_digit, prime_cnt=self.hash_cnt, mode="random")

    def hCount(self, value):
        if self.window_cnt < self.window_size:
            # window is not full
            self._insert(value)
        else:
            # window is full
            self._delete()
            self._insert(value)

    def hCount_star(self, value):
        if self.window_cnt < self.window_size:
            # window is not full
            self._insert(value)
        else:
            # window is full
            self._delete()
            self._insert(value)
            self._compensate_hash_collision()

    def verify(self, value):
        if self.window_cnt < self.window_size:
            # window is not full
            self._insert(value, ground_truth=True)
        else:
            # window is full
            self._delete(ground_truth=True)
            self._insert(value, ground_truth=True)

    def query_maxCount(self, value):
        value_set = []
        for i in range(self.hash_cnt):
            hash_idx = self._hash(value, i)
            #print("hash_idx: {}, type: {}".format(hash_idx, type(hash_idx)), flush=True)
            value_set.append(self.hash_table[i][hash_idx])
        return min(value_set)

    def query_all_maxCount(self, min_value, max_value):
        value_dict = {}
        for i in range(min_value, max_value):
            value_dict[i] = self.query_maxCount(i)
        return value_dict

    def query_eFreq(self, freq_threshold):
        pass

if __name__ == "__main__":
    # Generate data stream
    data_stream_length = 1000
    min_value = 0
    max_value = 100
    random_data = np.random.randint(low=min_value, high=max_value, size=data_stream_length)
    #random_data = np.arange(start=min_value, stop=max_value, step=1)

    # hCount
    hc = hCount(window_size=50, hash_cnt=10, m=100)
    print("initiating hash functions ...", flush=True)
    hc.init_hash(p_digit=3, a_digit=3, b_digit=3)
    print("hCount in progress ...", flush=True)
    for i in range(data_stream_length):
        hc.hCount(random_data[i])
    print("hCount done", flush=True)
    print(hc.query_all_maxCount(min_value, max_value))

    # Ground truth
    print("resetting parameters ...", flush=True)
    hc._reset_param()
    print("Ground truth in progress ...", flush=True)
    for i in range(data_stream_length):
        hc.verify(random_data[i])
    print("Ground truth done", flush=True)
    print(hc.ground_truth_dict)


