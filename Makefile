# TODO: Make this Makefile.in pretty

TARGETS = epserver epwget
CC=gcc -g -O3 -Wall -Werror -fgnu89-inline 
DPDK=1
PS=0
NETMAP=0
ONVM=0
CCP=
CFLAGS=-DMAX_CPUS=32

# Add arch-specific optimization
ifeq ($(shell uname -m),x86_64)
LIBS += -m64
endif

# mtcp library and header 
MTCP_FLD    =/home/sonic/mtcp/mtcp/
MTCP_INC    =-I${MTCP_FLD}/include
MTCP_LIB    =-L${MTCP_FLD}/lib
MTCP_TARGET = ${MTCP_LIB}/libmtcp.a

UTIL_FLD = /home/sonic/mtcp/util
UTIL_INC = -I${UTIL_FLD}/include
UTIL_OBJ = ${UTIL_FLD}/http_parsing.o ${UTIL_FLD}/tdate_parse.o ${UTIL_FLD}/netlib.o 

# util library and header
INC = -I./include/ ${UTIL_INC} ${MTCP_INC} -I${UTIL_FLD}/include
LIBS = ${MTCP_LIB}

# psio-specific variables
ifeq ($(PS),1)
PS_DIR = ../../io_engine/
PS_INC = ${PS_DIR}/include
INC += -I{PS_INC}
LIBS += -lmtcp -L${PS_DIR}/lib -lps -lpthread -lnuma -lrt
endif

# netmap-specific variables
ifeq ($(NETMAP),1)
LIBS += -lmtcp -lpthread -lnuma -lrt
endif

# dpdk-specific variables
ifeq ($(DPDK),1)
DPDK_MACHINE_LINKER_FLAGS=$${RTE_SDK}/$${RTE_TARGET}/lib/ldflags.txt
DPDK_MACHINE_LDFLAGS=$(shell cat ${DPDK_MACHINE_LINKER_FLAGS})
LIBS += -g -O3 -pthread -lrt -march=native ${MTCP_FLD}/lib/libmtcp.a -lnuma -lmtcp -lpthread -lrt -ldl -lgmp -L${RTE_SDK}/${RTE_TARGET}/lib ${DPDK_MACHINE_LDFLAGS} -luring
endif

# onvm-specific variables
ifeq ($(ONVM),1)
ifeq ($(RTE_TARGET),)
$(error "Please define RTE_TARGET environment variable")
endif

INC += -I/onvm_nflib
INC += -I/lib
INC += -DENABLE_ONVM
LIBS += /onvm_nflib/$(RTE_TARGET)/libonvm.a
LIBS += /lib/$(RTE_TARGET)/lib/libonvmhelper.a -lm
endif

ifeq ($V,) # no echo
	export MSG=@echo
	export HIDE=@
else
	export MSG=@\#
	export HIDE=
endif

ifeq ($(CCP), 1)
# LIBCCP
LIBCCP = $(MTCP_FLD)/src/libccp
LIBS += -L$(LIBCCP) -lccp -lstartccp
INC += -I$(LIBCCP)
endif

all: epserver epwget

epserver.o: epserver.c
	$(MSG) "   CC $<"
	$(HIDE) ${CC} -c $< ${CFLAGS} ${INC}

epserver: epserver.o ${MTCP_FLD}/lib/libmtcp.a
	$(MSG) "   LD $<"
	$(HIDE) ${CC} $< ${LIBS} ${UTIL_OBJ} -o $@

epwget.o: epwget.c
	$(MSG) "   CC $<"
	$(HIDE) ${CC} -c $< ${CFLAGS} ${INC}

epwget: epwget.o ${MTCP_FLD}/lib/libmtcp.a
	$(MSG) "   LD $<"
	$(HIDE) ${CC} $< ${LIBS} ${UTIL_OBJ} -o $@

clean:
	$(MSG) "   CLEAN $(TARGETS)"
	$(HIDE) rm -f *~ *.o ${TARGETS} log_*

distclean: clean
	rm -rf Makefile
