COMPONENT=Challenge3AppC
#CFLAGS=-DCC2420_DEF_CHANNEL=12
#CFLAGS+=-DTOSH_DATA_LENGTH=114
CFLAGS += -I$(TOSDIR)/lib/printf

#Comment this to disable logging
CFLAGS += -DLOGGING

include $(MAKERULES)


