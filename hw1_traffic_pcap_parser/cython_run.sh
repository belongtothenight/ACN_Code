# Make code executable when compiled
awk '{sub(/if __name__ == \"__main__\":/, "if __name__ != \"__main__\":"); print}' traffic_pcap_parser.pyx > traffic_pcap_parser_tmp.pyx

# Generate setup.py for cython
"import distutils.core
import Cython.Build

distutils.core.setup(ext_modules = Cython.Build.cythonize(`"traffic_pcap_parser_tmp.pyx`"))" > setup.py

# Compile the code
C:\Python312\python.exe .\setup.py build_ext --inplace
Remove-Item traffic_pcap_parser_tmp.pyx

# Generate execute.py to execute the compiled code
"import traffic_pcap_parser_tmp" > execute.py
C:\Python312\python.exe .\execute.py

rm execute.py
rm setup.py
rm *.pyd
rm *.c
