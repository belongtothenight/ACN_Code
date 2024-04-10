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

if __name__ == "__main__":
    # Parameters
    params = {
        "data_stream_length": 10000000,
        "window_size": 50000,
        "min_value": 0,     # 0, Must be 0
        "max_value": 100,   # M
        "hash_digit": 3,    # p
        "hash_Delta": 0.5,
        "epsilon": 0.01,
        "delta": 0.0001,
        }
    stream_type = "truncnorm" # "seq", "rand", "zipf1", "zipf2", "truncnorm"

    # Generate data stream
    if stream_type == "seq":
        random_data = np.arange(start=params["min_value"], stop=params["max_value"], step=1)
    elif stream_type == "rand":
        random_data = np.random.randint(low=params["min_value"], high=params["max_value"], size=params["data_stream_length"])
    elif stream_type == "zipf1":
        random_data = Zipf(a=1.1, min=np.uint64(1), max=np.uint64(params["max_value"]), size=params["data_stream_length"])
    elif stream_type == "zipf2": # overflow, error prone
        random_data = stats.zipf(a=1.1).rvs(size=params["data_stream_length"]).astype(np.uint64)
    elif stream_type == "truncnorm":
        # https://stackoverflow.com/questions/18441779/how-to-specify-upper-and-lower-limits-when-using-numpy-random-normal
        mu = 50
        sigma = 10
        random_data = stats.truncnorm((params["min_value"]-mu)/sigma, (params["max_value"]-mu)/sigma, loc=mu, scale=sigma).rvs(size=params["data_stream_length"]).astype(np.uint64)
    else:
        raise ValueError("Invalid stream type")
    print("Data stream generated", flush=True)

    # hCount
    hc = hCount(window_size=params["window_size"], delta=params["delta"], epsilon=params["epsilon"], max_value=params["max_value"], hash_digit=params["hash_digit"], hash_Delta=params["hash_Delta"], verbose=False)
    print("hCount in progress ...", flush=True)
    start_time = time.time()
    for i in range(params["data_stream_length"]):
        hc.hCount(random_data[i])
    print("hCount done in {} seconds".format(time.time()-start_time), flush=True)
    hc.compensate_hash_collision() # hCount star

    # Ground truth count
    print("Resetting ...", flush=True)
    hc.reset_param()
    print("Ground truth in progress ...", flush=True)
    start_time = time.time()
    for i in range(params["data_stream_length"]):
        hc.ground_truth(random_data[i])
    print("Ground truth done in {} seconds".format(time.time()-start_time), flush=True)

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
        # https://en.wikipedia.org/wiki/Precision_and_recall
        # TP = ground_truth - diff
        TP = df["ground_truth"].sum() - df["diff"].sum()
        writer.writerow(["TP?", TP])
        # FP = hCount - ground_truth
        FP = df["hCount"].sum() - df["ground_truth"].sum()
        writer.writerow(["FP?", FP])
        # FN = ground_truth - hCount
        FN = df["ground_truth"].sum() - df["hCount"].sum()
        writer.writerow(["FN?", FN])
        # TN = item_cnt - ground_truth - FP
        TN = len(df) - df["ground_truth"].sum() - FP
        writer.writerow(["TN?", TN])
        # precision = TP / (TP + FP)
        precision = TP / (TP + FP)
        writer.writerow(["precision?", precision])
        # recall = TP / (TP + FN)
        recall = TP / (TP + FN)
        writer.writerow(["recall?", recall])
        writer.writerow(["stream_type", stream_type])

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
    plt.ylabel("count (log scale)")
    plt.yscale("log")
    plt.title("hCount vs ground_truth (data stream: {})".format(stream_type))
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
    plt.title("hCount - ground_truth = diff (data stream: {})".format(stream_type))
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
    plt.ylabel("freq (log scale)")
    plt.yscale("log")
    plt.title("eFreq (data stream: {})".format(stream_type))
    plt.savefig(filename)
    plt.close()
