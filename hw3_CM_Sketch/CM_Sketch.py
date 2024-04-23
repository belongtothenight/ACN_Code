import numpy as np
import os

class CM_Sketch():
    def __init__(self, epsilon: float, delta: float, omega: int =100, verbose: bool =False, data_dir: str ="data") -> None:
        # Input range: [1, ..., n]
        # Output range: [1, ..., omega]
        self.epsilon = epsilon
        self.delta = delta
        self.omega = omega
        self.verbose = verbose
        self.data_dir = data_dir
        self.primes = []
        self.ground_truth_dict = {}
        self._cal_params()
        if self.verbose:
            self._display_params()
        self._init_hash()

    def _cal_params(self) -> None:
        # hash_digit should be at least int(log_10(omega)) + 1
        self.hash_digit = int(np.ceil(np.log10(self.omega))) + 1
        self.width = int(np.ceil(np.exp(1) / self.epsilon))
        self.depth = int(np.ceil(np.log(1 / self.delta)))
        self.hash_cnt = self.depth
        self.hash_m = self.width
        self.hash_table = np.zeros((self.depth, self.width), dtype=int)

    def _display_params(self) -> None:
        print(f"Width: {self.width}, Depth: {self.depth}, Hash digit: {self.hash_digit}")

    # From https://github.com/belongtothenight/ACN_Code/blob/main/hw2_hCount/hCount.py#L44
    # mode: last, random, ... (default: last)
    def _gen_prime(self, mode: str ="last", prime_cnt: int =1):
        def is_prime(num):
            if num == 0 or num == 1:
                return False
            for x in range(2, num):
                if num % x == 0:
                    return False
            return True
        if len(self.primes) == 0: # cache primes
            self.primes = list(filter(is_prime, range(10 ** (self.hash_digit-1), 10 ** (self.hash_digit))))
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

    # From https://github.com/belongtothenight/ACN_Code/blob/main/hw2_hCount/hCount.py#L70
    def _init_hash(self):
        if self.verbose:
            print("Generating hash p ...", flush=True)
        self.hash_p = self._gen_prime(mode="last")
        if self.verbose:
            print("Generating hash a ...", flush=True)
        self.hash_a = self._gen_prime(prime_cnt=self.hash_cnt, mode="random")
        if self.verbose:
            print("Generating hash b ...", flush=True)
        self.hash_b = self._gen_prime(prime_cnt=self.hash_cnt, mode="random")

    # From https://github.com/belongtothenight/ACN_Code/blob/main/hw2_hCount/hCount.py#L81
    def _hash(self, value: int, hash_idx: int):
        return int(((self.hash_a[hash_idx] * value + self.hash_b[hash_idx]) % self.hash_p) % self.hash_m)

    # From https://github.com/belongtothenight/ACN_Code/blob/main/hw2_hCount/hCount.py#L84
    def _group_hash(self, value: int):
        for i in range(self.hash_cnt):
            hash_idx = self._hash(value, i)
            if self.verbose:
                print("hash_idx: {}, type: {}".format(hash_idx, type(hash_idx)), flush=True)
            self.hash_table[i][hash_idx] += 1

    def update(self, value: int, ground_truth: bool =False):
        if not ground_truth:
            self._group_hash(value)
        else:
            if value in self.ground_truth_dict:
                self.ground_truth_dict[value] += 1
            else:
                self.ground_truth_dict[value] = 1

    def dump_table(self, filename: str ="hash_table.csv"):
        if not os.path.exists(self.data_dir):
            os.makedirs(self.data_dir)
        csv_path = os.path.join(self.data_dir, filename)
        if os.path.exists(csv_path):
            os.remove(csv_path)
        np.savetxt(csv_path, self.hash_table, delimiter=",", fmt="%d")

    def query(self, value: int, ground_truth: bool =False):
        if not ground_truth:
            return min([self.hash_table[i][self._hash(value, i)] for i in range(self.hash_cnt)])
        else:
            try:
                return self.ground_truth_dict[value]
            except KeyError:
                return 0

    def group_query(self, min_value: int, max_value: int, ground_truth: bool =False):
        result_dict = {}
        for value in range(min_value, max_value):
            if not ground_truth:
                result_dict[value] = self.query(value)
            else:
                result_dict[value] = self.query(value, ground_truth=True)
        return result_dict
