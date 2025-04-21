HOST:=$(shell gcc -dumpmachine)
TARGET=$(HOST)

ifneq (,$(findstring mingw,$(TARGET)))
 EXESUFFIX=.exe
else
 EXESUFFIX=
endif

ifneq ($(TARGET),$(HOST))
 GNATPREFIX=$(TARGET)-
 BINLN=
else
 GNATPREFIX=
 BINLN=bin
endif

DEBUG=1

ifneq ($(filter-out 0 1,$(DEBUG)),)
 BUILDDIR=$(TARGET).noindex/debug
 LINK=
else
 BUILDDIR=$(TARGET).noindex
 LINK=gc
endif

CFLAGS=-pipe
CFLAGS_ADA=-gnatef -gnatwaI
LDFLAGS=

ifneq ($(findstring freebsd,$(TARGET)),)
 LDFLAGS+=-lm -lgcc_eh -lpthread
endif

ifeq ($(LINK),gc)
 ifneq ($(findstring darwin,$(TARGET)),)
  LDFLAGS+=-dead_strip
  ifneq ($(WHYLIVE),)
   LDFLAGS+=-Wl,-why_live,$(WHYLIVE)
  endif
 else
  CFLAGS+=-ffunction-sections -fdata-sections
  LDFLAGS+=-Wl,--gc-sections
 endif
else ifeq ($(LINK),lto)
 CFLAGS+=-flto
 LDFLAGS+=-flto
endif

ifneq ($(filter-out 0 1,$(DEBUG)),)
 CFLAGS+=-Og -fno-guess-branch-probability
 CFLAGS_ADA+=-gnata
 LDFLAGS+=-Og
else
 CFLAGS+=-Os
 CFLAGS_ADA+=-gnatB -gnatn2 -gnatVn
 LDFLAGS+=-Os
endif
ifneq ($(filter-out 0,$(DEBUG)),)
 CFLAGS+=-ggdb$(DEBUG)
 LDFLAGS+=-ggdb$(DEBUG)
 ifneq ($(findstring freebsd,$(TARGET))$(findstring linux-gnu,$(TARGET)),)
  LDFLAGS+=-Wl,--compress-debug-sections=zlib
 endif
endif

RTSDIR?= # specifying it to drake is prerequisite

ADC=$(wildcard *.adc)

GARGS=$(addprefix --RTS=,$(RTSDIR))
MARGS=-C -D $(BUILDDIR) -gnatA $(addprefix -gnatec=,$(ADC)) \
      $(addprefix -I,$(and $(ADC),.))
CARGS=$(CFLAGS) $(CFLAGS_ADA)
BARGS=-E -x
LARGS=$(LDFLAGS)
FARGS=

DESTDIR=
PREFIX=/usr/local
BINDIR=$(PREFIX)/bin

.PHONY: all clean install install-bin xfind xfindall

all: $(BUILDDIR)/longlines$(EXESUFFIX) $(BINLN)

$(BUILDDIR)/longlines$(EXESUFFIX): source/longlines.adb | $(BUILDDIR)
	$(GNATPREFIX)gnatmake -c $< $(MARGS) $(GARGS) -cargs $(CARGS)
	cd $(BUILDDIR) && $(GNATPREFIX)gnatbind $(basename $(notdir $<)).ali $(GARGS) $(BARGS)
	cd $(BUILDDIR) && $(GNATPREFIX)gnatlink -o $(notdir $@) $(basename $(notdir $<)).ali $(GARGS) $(LARGS)

$(BINLN): | $(BUILDDIR)
	ln -s $(BUILDDIR) $@

$(BUILDDIR):
	@$(if $(RTSDIR),,$(warning RTSDIR is unset)false)
	mkdir -p $@

clean:
	-$(if $(BINLN),[ -h "$(BINLN)" ] && rm "$(BINLN)")
	-rm -r $(BUILDDIR)

install: install-bin

install-bin: $(BUILDDIR)/longlines$(EXESUFFIX) | $(DESTDIR)$(BINDIR)
	install -s $< $(DESTDIR)$(BINDIR)

$(DESTDIR)$(BINDIR):
	mkdir -p $@

xfind:
	gnatfind -f -aIsource -aO$(BUILDDIR) $(X) $(GARGS) $(FARGS) | sed 's|^$(PWD)/||'

xfindall: FARGS+=-r
xfindall: xfind
