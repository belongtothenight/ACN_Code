from CM_Sketch import CM_Sketch
from gen_stream import gen_seq, gen_rand, gen_uniform, gen_zipf1, gen_zipf2, gen_truncnorm
import pandas as pd
import os
import matplotlib.pyplot as plt

if __name__ == "__main__":
    # CM Sketch Parameters
    cm_param = {
            'epsilon': 0.01,
            'delta': 0.0001,
            'omega': 100,
            'verbose': False,
            'data_dir': 'data',
            }

    # Stream Parameters
    stream_param = {
            'min_value': 1,
            'max_value': cm_param['omega']+1,
            'length': 10000,
            #'length': 100,
            'sigma': 10,
            'mu': 50,
            }
    #stream = gen_rand(min_value=stream_param['min_value'], max_value=stream_param['max_value'], length=stream_param['length'])
    stream = gen_truncnorm(min_value=stream_param['min_value'], max_value=stream_param['max_value'], length=stream_param['length'], sigma=stream_param['sigma'], mu=stream_param['mu'])
    #stream = gen_uniform(min_value=stream_param['min_value'], max_value=stream_param['max_value'], length=stream_param['length'])

    # MA/Windowed Count-Min Update
    window_size = 9990
    #window_size = 10
    element_history = []

    # Since CM Sketch does not have removal operation, we need to create a new CM Sketch for each window
    for i in range(0, stream_param['length']-window_size+1):
        print(f"Window {i+1}/{stream_param['length']-window_size+1}", end='\r')
        cm = CM_Sketch(epsilon=cm_param['epsilon'], delta=cm_param['delta'], omega=cm_param['omega'], verbose=cm_param['verbose'], data_dir=cm_param['data_dir'])
        for value in stream[i:i+window_size]:
            cm.update(value)
        element_history.append(cm.get_F2(min_value=stream_param['min_value'], max_value=stream_param['max_value']))
        del cm
    print(element_history)

    # Plot Query Results
    path = 'plot'
    if not os.path.exists(path):
        os.makedirs(path)
    plot_file = os.path.join(path, 'count_trend.png')
    if os.path.exists(plot_file):
        os.remove(plot_file)
    plt.figure()
    plt.plot([i for i in range(0, stream_param['length']-window_size+1)], element_history, label='Count Trend')
    plt.xlabel('Window')
    plt.ylabel('Count')
    plt.legend()
    plt.savefig(plot_file)
    plt.close()
