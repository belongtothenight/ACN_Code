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
            'omega': 99,
            'verbose': False,
            'data_dir': 'data',
            }

    cm = CM_Sketch(epsilon=cm_param['epsilon'], delta=cm_param['delta'], omega=cm_param['omega'], verbose=cm_param['verbose'], data_dir=cm_param['data_dir'])

    # Stream Parameters
    stream_param = {
            'min_value': 1,
            'max_value': cm_param['omega']+1,
            'length': 10000,
            'sigma': 10,
            'mu': 50,
            }
    #stream = gen_rand(min_value=stream_param['min_value'], max_value=stream_param['max_value'], length=stream_param['length'])
    stream = gen_truncnorm(min_value=stream_param['min_value'], max_value=stream_param['max_value'], length=stream_param['length'], sigma=stream_param['sigma'], mu=stream_param['mu'])
    #stream = gen_uniform(min_value=stream_param['min_value'], max_value=stream_param['max_value'], length=stream_param['length'])

    # Update CM Sketch
    for value in stream:
        cm.update(value, ground_truth=False)
        cm.update(value, ground_truth=True)
    cm.dump_table()

    # Compare Query Results
    df = pd.DataFrame()
    df['value'] = [i for i in range(stream_param['min_value'], stream_param['max_value'])]
    df['cm_result'] = df['value'].map(cm.group_query(min_value=stream_param['min_value'], max_value=stream_param['max_value']))
    df['gt_result'] = df['value'].map(cm.group_query(min_value=stream_param['min_value'], max_value=stream_param['max_value'], ground_truth=True))
    df['diff'] = df['gt_result'] - df['cm_result']
    csv_file = os.path.join(cm_param['data_dir'], 'query_result.csv')
    if os.path.exists(csv_file):
        os.remove(csv_file)
    df.to_csv(csv_file, index=False)

    # Plot Query Results
    path = 'plot'
    if not os.path.exists(path):
        os.makedirs(path)
    plot_file = os.path.join(path, 'query_result.png')
    if os.path.exists(plot_file):
        os.remove(plot_file)
    plt.figure()
    plt.plot(df['value'], df['cm_result'], label='CM Sketch', alpha=0.5)
    plt.plot(df['value'], df['gt_result'], label='Ground Truth', alpha=0.5)
    plt.xlabel('Value')
    plt.ylabel('Count')
    plt.legend()
    plt.savefig(plot_file)
    plt.close()
