srcfiles := $(shell find home -type f)
destfiles := $(patsubst home/%,~/%,$(srcfiles))

all: links chmod

home/%:
	@[ -d $(dir ~/$*) ] || mkdir -p $(dir ~/$*)
	@[ -f ~/$* ] || ln -s $(realpath $@) ~/$*

links: $(srcfiles)

chmod:
	chmod +x home/bin/*

setup: fedora_setup code_extensions

fedora_setup:
	sudo ./fedora_setup

code_extensions:
	./code_extensions

clean:
	rm -rf $(destfiles)

.PHONY: links