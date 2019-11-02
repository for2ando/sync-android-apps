# Makefile for sync-android-apps

INSTDIR=$(HOME)/bin
INSTFILES=saa-make-list saa-make-desc saa-copy-saadir saa-get-apps saa-put-apps

install: $(INSTFILES)
	install --target-directory=$(INSTDIR) $^

diff: $(INSTFILES)
	$(foreach i,$^,diff -u $(INSTDIR)/$i $i;)
