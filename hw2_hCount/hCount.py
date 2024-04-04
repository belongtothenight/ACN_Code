import numpy as np
import time

class hCount:
    def __init__(self, window_size, hash_cnt, m):
        # paper parameter
        self.window_cnt = 0
        self.hash_table = np.zeros((hash_cnt, m))
        self.hash_a = np.zeros(hash_cnt)
        self.hash_b = np.zeros(hash_cnt)
        self.hash_p = 0
        self.hash_m = m
        self._init_hash()
        # circular buffer
        self.window_size = window_size
        self.window_data = np.zeros(window_size)
        self.window_cursor = 0

    def _init_hash(self):
        pass

    def __hash(self, value, hash_idx):
        pass

    def __group_hash(self, value):
        pass

    def _insert(self, value):
        self.window_cnt += 1
        self.window_data[self.window_cursor] = value
        self.window_cursor = (self.window_cursor + 1) % self.window_size

    def _delete(self):
        self.window_cnt -= 1

    def _compensate_hash_collision(self):
        pass

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

    def query_maxCount(value):
        pass

    def query_eFreq(self, freq_threshold):
        pass

    def dump_window_cnt(self):
        return self.window_cnt

    def dump_window(self):
        return self.window_data

    def dump_window_cursor(self):
        return self.window_cursor

if __name__ == "__main__":
    data_stream_length = 100
    #random_data = np.random.randint(low=0, high=100, size=data_stream_length)
    random_data = np.arange(start=0, stop=data_stream_length, step=1)
    hc = hCount(window_size=10, hash_cnt=10, m=100)
    for i in range(data_stream_length):
        hc.hCount(random_data[i])
        print(hc.dump_window())
        print(hc.dump_window_cursor())
