# hCount Implementation

This is a Python implementation of the hCount algorithm for data stream processing from paper [Dynamically Maintaining Frequent Items Over A Data Stream](https://users.monash.edu/~mgaber/jin-cikm03.pdf).

- hCount
- eFreq
- hCount $\star$

## Execution

1. Navigate to this directory in your terminal.
2. Initialize environment with:
    ```pwsh Windows PowerShell
    ./scripts/setup.ps1
    ```
    ```bash Linux Bash (use source to keep environment variables)
    source ./scripts/setup.sh
    ```
3. Execute program:
    ```pwsh Windows PowerShell
    python main.py
    ```
    ```bash Linux Bash
    python main.py
    ```
4. Clean up environment with:
    ```pwsh Windows PowerShell
    ./scripts/remove.ps1
    ```
    ```bash Linux Bash
    ./scripts/remove.sh
    ```
    
## Structure

- [scripts](scripts): Contains scripts for setting up and cleaning up local execution environment.
- [.gitignore](.gitignore): Files and directories to be ignored by git.
- [hCount.py](hCount.py): Implementation of hCount algorithm in Python class.
- [main.py](main.py): Main program to execute hCount algorithm.
- [readme.md](readme.md): This file.
- [requirements.txt](requirements.txt): Python packages required for execution.

## Class hCount Documentation

- `hCount.__init__(window_size: int, delta: float, epsilon: float, max_value: int, hash_digit: int, hash_Delta: float = 0 , verbose: bool = False) -> None`: Constructor for hCount class.
    - `window_size`: Size of data stream window to keep track of.
    - `delta`: Error probability. (0~1)
    - `epsilon`: Error factor. (How likely the error is to be within delta) (0~1)
    - `max_value`: Maximum value of data stream.
    - `hash_digit`: Number of digits of prime numbers to use in hash function. (Recommended to be larger than input item, takes a long time to compute)
    - `hash_Delta`: hCount $\star$ parameter in percentage, extra space for collision calculation. (0~1)
    - `verbose`: Print debug information if True. (Set accross all functions)
- `hCount._cal_params() -> None`: Helper function to calculate data structure (hash table) dimension.
- `hCount._gen_prime(mode: str = 'last', prime_cnt: int = 1) -> int/List[int]`: Helper function to generate prime number(s).
    - `mode`: 'last' to return largest prime number(s), 'random' to return random prime number(s), or to return smallest prime number(s).
    - `prime_cnt`: Number of prime numbers to return.
- `hCount._init_hash() -> None`: Helper function to initialize hash functions.
- `hCount._hash(value: int, hash_idx: int) -> int`: Helper function to hash value with specified hash function.
    - `value`: Value to hash.
    - `hash_idx`: Index of hash function to use.
- `hCount._group_hash(value: int, mode_add: bool = True) -> None`: Helper function to group hash value and add or remove from hash table.
    - `value`: Value to hash.
    - `mode_add`: True to add value to hash table, False to remove value from hash table.
- `hCount._insert(value: int, ground_truth: bool = False) -> None`: Helper function, hCount core function, to insert value to hash table or ground truth dictionary.
    - `value`: Value to insert.
    - `ground_truth`: True to insert value to ground truth dictionary, False to insert value to hash table.
- `hCount._delete(ground_truth: bool = False) -> None`: Helper function, hCount core function, to delete value from hash table or ground truth dictionary. Circular buffer is used so no need to specify value.
    - `ground_truth`: True to insert value to ground truth dictionary, False to insert value to hash table.
- `hCount.reset_param() -> None`: Reset circular buffer and window to initial state.
- `hCount.hCount(value: int) -> None`: hCount algorithm to accept new arriving value and update hash table.
    - `value`: New arriving value.
- `hCount.ground_truth(value: int) -> None`: Ground truth to accept new arriving value and update ground truth dictionary.
    - `value`: New arriving value.
- `hCount.compensate_hash_collision() -> None`: hCount $\star$ algorithm to compensate hash collision.
- `hCount.query_maxCount(value: int) -> int`: Query hash table to get maximum possible count of value. (minimum of all queries)
    - `value`: Value to query.
- `hCount.query_all_maxCount() -> dict[item: int, count: int]`: Query hash table to get all maximum possible counts of all items.
- `hCount.query_eFreq(freq_threshold: float =0.01) -> list[item: int]`: Query hash table to get all items with frequency greater than threshold.
    - `freq_threshold`: Frequency threshold in range (0, 1).
- `hCount.query_all_eFreq() -> dict[item: int, freq: float]`: Query hash table to get all items' frequency.
- `hCount.dump_general_params(params: dict[param: str, value: any]) -> None`: Dump general parameters to CSV file.
    - `params`: Dictionary of parameters to dump. (constructor parameters)
- `hCount.dump_hash_params() -> None`: Dump hash function parameters to CSV file.
