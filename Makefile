# include ../../../../lib/yaws/include.mk

all:	forums.beam
	cp -f forums.beam ../../../../lib/yaws/examples/ebin
debug:

install:	all
	cp -f forums.beam $(DESTDIR)$(VARDIR)/yaws/ebin

clean:
	$(RM) -f forums.beam
	$(RM) -f ../../../../lib/yaws/examples/ebin/forums.beam

forums.beam:	forums.erl
	erlc forums.erl
