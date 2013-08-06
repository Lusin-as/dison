COMPONENT=TestDisonApp

CFLAGS += -I$(TOSDIR)/lib/net \
	  -I$(TOSDIR)/lib/net/ctp \
          -I$(TOSDIR)/lib/net/drip \
          -I$(TOSDIR)/lib/net/4bitle \
	  -I$(TOSDIR)/lib/printf/
#CFLAGS += -I /home/trang/workspace/DisonNew/src
CFLAGS += -I$(TOSROOT)/apps/DisonNew/src \

#CFLAGS += -DCC2420_DEF_RFPOWER=3

#TFLAGS += -I$(TOSDIR)/types \
#          -I.
		  
PFLAGS += -DTOSH_DATA_LENGTH=90 -DCELL_ID=4 -DUSE_DISON=0
#-DAUTOEVAL -DUSE_DISON
#-DNO_DEBUG

include $(MAKERULES)

