# Generate setup.py for cython
"import distutils.core
import Cython.Build

distutils.core.setup(ext_modules = Cython.Build.cythonize(`"traffic_pcap_parser.pyx`"))" > setup.py
python3 .\setup.py build_ext --inplace

# Generate execute.py to execute the compiled code
"import traffic_pcap_parser" > execute.py
python3 .\execute.py

rm execute.py
rm setup.py
rm *.pyd
rm *.c
