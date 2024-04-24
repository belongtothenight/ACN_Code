# CM Sketch Implementation

## Structure

- [./scripts](./scripts): Scripts for setting up and removing the python environment. (Python39)
- [./gitignore](./gitignore): Gitignore file.
- [./CM_Sketch.py](./CM_Sketch.py): CM Sketch implementation Python library.
- [./gen_stream.py](./gen_stream.py): Stream generator functions.
- [./q1.py](./q1.py): Question 1 implementation with implemented CM Sketch.
- [./q2.py](./q2.py): Question 2 implementation with implemented CM Sketch.
- [./readme.md](./readme.md): This file.
- [./requirements.txt](./requirements.txt): Python library requirements.

## Questions

### Q1

Please implement the Count-Min Sketch algorithm to estimate the second frequency moment (F2) by programming, and then utilize frequency moments for traffic analysis.

### Q2

Please apply the moving average methodology to analyze trends.

## Formula

While $m$ is the stream length count.

1. $F_k$ score (frequency moment): $F_k=\sum f^k_i$
2. $F_0$ score (distinct item count): $F_0=\sum^{n=m}_{i=1}f_i^0=f_1^0+f_2^0+\cdots+f_m^0$
3. $F_1$ score (total item count): $F_1=\sum^{n=m}_{i=1}f_i^1=f_1+f_2+\cdots+f_m$
4. $F_2$ score (item count variation): $F_2=\sum^{n=m}_{i=1}f_i^2=f_1^2+f_2^2+\cdots+f_m^2$
5. Mersenne Prime aided hash (pseudo-code)
    ```algorithm
    p = 2^s - 1;
    int i = (k & p) + (k >> s);
    return (i >= p) ? i - p : i; # If i >= p, return i - p, else return i
    ```
