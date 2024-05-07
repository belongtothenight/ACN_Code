project = ACN_Code
common_cflag = -Wno-implicit-function-declaration -Wextra -Wall -Wfloat-equal -Wundef -Wshadow -Wpointer-arith -Wcast-align -Wstrict-prototypes -Wstrict-overflow=5 -Wwrite-strings -Waggregate-return -Wcast-qual -Wswitch-default -Wswitch-enum -Wconversion -Wunreachable-code -Wformat=2 -O2
common_cxxflag = -Wextra -Wall -Wfloat-equal -Wundef -Wshadow -Wpointer-arith -Wcast-align -Wstrict-overflow=5 -Wwrite-strings -Waggregate-return -Wcast-qual -Wswitch-default -Wswitch-enum -Wconversion -Wunreachable-code -Wformat=2 -O2

# ====================================
# install directory of public:
# - plugins         (.so, .a, .la)
# - libtool library (.so, .a, .la)
# - header          (.h)
# - binary
# NOTE: comment out if not needed of individual install
# NOTE: created directory won't be removed by uninstall
# NOTE: header ladir need to use the library name as prefix
# ====================================
libdir              = $(prefix)/lib/${project}
lib_common_ladir    = $(prefix)/include/${project}
bindir              = $(prefix)/bin/${project}
pt_packet_countdir  = $(prefix)/bin/${project}
pt_iatdir           = $(prefix)/bin/${project}

# ====================================
# add library to install as plugin
# NOTE: can't be used with plugin_LTLIBRARIES
# ====================================
lib_LTLIBRARIES = lib_common.la

# ====================================
# add source to build library
# NOTE: need to use the library name as prefix
# ====================================
lib_common_la_SOURCES = lib_output_format.c \
                        lib_signal_handler.c \
                        lib_error.c
lib_common_la_HEADERS = lib_output_format.h \
                        lib_signal_handler.h \
                        lib_error.h
lib_common_la_CFLAGS = $(common_cflag)
lib_common_la_LDFLAGS = -Wl, --no-as-needed

# ====================================
# add executable to build
# ====================================
bin_PROGRAMS   = pt_count_packet \
                 pt_quantize_iat

# ====================================
# add source to build executable
# NOTE: need to use the executable name as prefix
# ====================================
pt_count_packet_SOURCES = pt_count_packet.c
                          #lib_error.c
#pt_count_packet_HEADERS = lib_error.h
pt_count_packet_CFLAGS = $(common_cflag)
pt_count_packet_LDADD = lib_common.la -ltrace -lm -L/usr/local/lib
pt_count_packet_LDFLAGS = -I/usr/local/include
pt_quantize_iat_SOURCES = pt_quantize_iat.c
                          #lib_error.c
#pt_quantize_iat_HEADERS = lib_error.h
pt_quantize_iat_CFLAGS = $(common_cflag)
pt_quantize_iat_LDADD = lib_common.la -ltrace -lm -L/usr/local/lib
pt_quantize_iat_LDFLAGS = -I/usr/local/include
