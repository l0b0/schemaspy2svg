prefix = /usr/local
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
datarootdir = $(prefix)/share
datadir = $(datarootdir)

my_datadir = $(datadir)/$(notdir $(CURDIR))
my_exec = $(prefix)/bin/$(notdir $(CURDIR))
my_escaped_path = $(shell echo "$(my_datadir)" | sed -e 's/\(\/\|\\\|&\)/\\&/g')

.PHONY: install
install:
	install $(notdir $(CURDIR)).sh $(DESTDIR)$(my_exec)
	install -d $(DESTDIR)$(my_datadir)
	install schemaSpy.css.patch $(DESTDIR)$(my_datadir)
	sed -i -e "s/^patch_path=.*/patch_path=$(my_escaped_path)\/schemaSpy.css.patch/" $(DESTDIR)$(my_exec)

.PHONY: uninstall
uninstall:
	rm $(DESTDIR)$(my_exec)
	rm $(DESTDIR)$(my_datadir)/schemaSpy.css.patch
	rmdir $(DESTDIR)$(my_datadir)

include tools.mk
