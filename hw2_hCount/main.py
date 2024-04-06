from hCount import hCount
import numpy as np
import pandas as pd
import os
import csv
import matplotlib.pyplot as plt

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
        }

    # Generate data stream
    #random_data = np.arange(start=params["min_value"], stop=params["max_value"], step=1)
    #random_data = np.random.randint(low=params["min_value"], high=params["max_value"], size=params["data_stream_length"])
    random_data = Zipf(a=1.1, min=np.uint64(1), max=np.uint64(params["max_value"]), size=params["data_stream_length"])
    #params["max_value"] = max(random_data)
    print("Data stream generated", flush=True)

    # hCount
    hc = hCount(window_size=params["window_size"], delta=params["delta"], epsilon=params["epsilon"], max_value=params["max_value"], hash_digit=params["hash_digit"], hash_Delta=params["hash_Delta"], verbose=False)
    print("hCount in progress ...", flush=True)
    for i in range(params["data_stream_length"]):
        hc.hCount(random_data[i])
    print("hCount done", flush=True)
    hc.compensate_hash_collision() # hCount star

    # Ground truth count
    print("Resetting ...", flush=True)
    hc.reset_param()
    print("Ground truth in progress ...", flush=True)
    for i in range(params["data_stream_length"]):
        hc.ground_truth(random_data[i])
    print("Ground truth done", flush=True)

    # eFreq
    freq_threshold = 0.01
    print("eFreq items of frequency {} are: {}".format(freq_threshold, hc.query_eFreq(freq_threshold)), flush=True)

    # Dump
    hc.dump_general_params(params)
    hc.dump_hash_params()

    # Compare
    print("Comparing ...", flush=True)
    filename = "data/hCount.csv"
    if os.path.exists(filename):
        os.remove(filename)
    df = pd.DataFrame()
    df["item"] = list(hc.ground_truth_dict.keys())
    df["ground_truth"] = df["item"].map(hc.ground_truth_dict)
    df["hCount"] = [hc.query_maxCount(i) for i in df["item"]]
    df["diff"] = df["hCount"] - df["ground_truth"]
    df["eFreq"] = df["item"].map(hc.query_all_eFreq())
    df.sort_values(by="item", inplace=True)
    df.to_csv(filename, index=False)
    print("Comparing done", flush=True)

    # Append statistics
    with open("data/hCount_general.csv", "a", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["item_cnt", len(df)])
        writer.writerow(["ground_truth_sum", df["ground_truth"].sum()])
        writer.writerow(["hCount_sum", df["hCount"].sum()])
        writer.writerow(["diff_sum", df["diff"].sum()])

    plot_dir = "plots"
    if not os.path.exists(plot_dir):
        os.makedirs(plot_dir)

    # Plot 1: ground_truth vs hCount
    print("Plotting plot 1 ...", flush=True)
    filename = os.path.join(plot_dir, "ground_truth_vs_hCount.png")
    if os.path.exists(filename):
        os.remove(filename)
    plt.figure()
    plt.plot(df["item"], df["ground_truth"], label="ground_truth", alpha=0.5)
    plt.plot(df["item"], df["hCount"], label="hCount", alpha=0.5)
    plt.legend()
    plt.xlabel("item")
    plt.ylabel("count")
    plt.yscale("log")
    plt.title("hCount")
    plt.savefig(filename)
    plt.close()

    # Plot 2: diff
    print("Plotting plot 2 ...", flush=True)
    filename = os.path.join(plot_dir, "diff.png")
    if os.path.exists(filename):
        os.remove(filename)
    plt.figure()
    plt.plot(df["item"], df["diff"], label="diff")
    plt.legend()
    plt.xlabel("item")
    plt.ylabel("count")
    plt.title("hCount - ground_truth = diff")
    plt.savefig(filename)
    plt.close()

    # Plot 3: eFreq
    print("Plotting plot 3 ...", flush=True)
    filename = os.path.join(plot_dir, "eFreq.png")
    if os.path.exists(filename):
        os.remove(filename)
    plt.figure()
    plt.plot(df["item"], df["eFreq"], label="eFreq")
    plt.legend()
    plt.xlabel("item")
    plt.ylabel("freq")
    plt.yscale("log")
    plt.title("eFreq")
    plt.savefig(filename)
    plt.close()
