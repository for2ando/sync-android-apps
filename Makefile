# Makefile for sync-android-apps
.PHONY: install diff prepare

INSTDIR=$(HOME)/bin
INSTFILES=saa-make-list saa-make-desc saa-make-apkver saa-copy-saadir saa-get-apps saa-put-apps saa-rm-apps saa-environ.sh saat-merge-lists saat-select-newver
IMPORTDIR1=../copy-android-apps
IMPORTFILES1=run.sh adbwrappers.sh in_args.sh
IMPORTDIR2=../trapwrapper
IMPORTFILES2=trapwrapper.sh

install: $(INSTFILES)
	install --target-directory=$(INSTDIR) $^

diff: $(INSTFILES)
	$(foreach instfile,$^,diff -u $(INSTDIR)/$(instfile) $(instfile);)

prepare: $(IMPORTFILES1) $(IMPORTFILES2)

clean:
	rm -f $(IMPORTFILES1) $(IMPORTFILES2)

$(IMPORTFILES1): $(IMPORTDIR1)
	ln -sf $(addprefix $^/,$@) .

$(IMPORTFILES2): $(IMPORTDIR2)
	ln -sf $(addprefix $^/,$@) .

$(IMPORTDIR1):
	cd $(dir $@) && git clone git@github.com:for2ando/copy-android-apps.git $(notdir $@)

$(IMPORTDIR2):
	cd $(dir $@) && git clone git@github.com:for2ando/trapwrapper.git $(notdir $@)
