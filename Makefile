# Makefile for sync-android-apps

INSTDIR=$(HOME)/bin
INSTFILES=saa-make-list saa-make-desc saa-copy-saadir saa-get-apps saa-put-apps

install: $(INSTFILES)
	install --target-directory=$(INSTDIR) $^

diff: $(INSTFILES)
	$(foreach instfile,$^,diff -u $(INSTDIR)/$(instfile) $(instfile);)

WORKDIR1=../copy-android-apps
FILES_IN_WORKDIR1=run.sh adbwrappers.sh

.PHONY: prepare
prepare: $(FILES_IN_WORKDIR1)

$(FILES_IN_WORKDIR1): $(WORKDIR1)
	ln -sf $(addprefix $^/,$@) .

$(WORKDIR1):
	cd $(dir $@) && git clone git@github.com:for2ando/copy-android-apps.git $(notdir $@)
