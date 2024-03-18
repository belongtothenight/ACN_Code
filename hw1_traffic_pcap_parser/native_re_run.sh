# Remove lines with "cdef" from PYX file, exclude class definition
awk '!/cdef/ || /cdef class/' traffic_pcap_parser.pyx > traffic_pcap_parser_re.py.tmp
# Remove "cdef" from the beginning of the class definition (not limited)
awk '{sub(/cdef /, ""); print}' traffic_pcap_parser_re.py.tmp > traffic_pcap_parser_re.py
rm traffic_pcap_parser_re.py.tmp

python3 traffic_pcap_parser_re.py

rm traffic_pcap_parser_re.py
