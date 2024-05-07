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
tp_packet_countdir  = $(prefix)/bin/${project}
tp_iatdir           = $(prefix)/bin/${project}

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
bin_PROGRAMS   = tp_packet_count \
                 tp_iat

# ====================================
# add source to build executable
# NOTE: need to use the executable name as prefix
# ====================================
tp_packet_count_SOURCES = tp_packet_count.c
                          #lib_error.c
#tp_packet_count_HEADERS = lib_error.h
tp_packet_count_CFLAGS = $(common_cflag)
tp_packet_count_LDADD = lib_common.la -ltrace -lm -L/usr/local/lib
tp_packet_count_LDFLAGS = -I/usr/local/include
tp_iat_SOURCES = tp_iat.c
                 #lib_error.c
#tp_iat_HEADERS = lib_error.h
tp_iat_CFLAGS = $(common_cflag)
tp_iat_LDADD = lib_common.la -ltrace -lm -L/usr/local/lib
tp_iat_LDFLAGS = -I/usr/local/include
