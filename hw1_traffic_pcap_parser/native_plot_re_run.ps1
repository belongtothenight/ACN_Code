# Remove lines with "cdef" from PYX file, exclude class definition
awk '!/cdef/ || /cdef class/' traffic_pcap_parser.pyx > traffic_pcap_parser_re.py.tmp
# Remove "cdef" from the beginning of the class definition (not limited)
awk '{sub(/cdef /, ""); print}' traffic_pcap_parser_re.py.tmp > traffic_pcap_parser_re.py
Remove-Item traffic_pcap_parser_re.py.tmp

C:\Python312\python.exe execute.py

Remove-Item traffic_pcap_parser_re.py
