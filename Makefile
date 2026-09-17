srcfiles := $(shell find home -type f)
destfiles := $(patsubst home/%,~/%,$(srcfiles))

.PHONY: all
all: links

home/%:
	@[ -d $(dir ~/$*) ] || mkdir -p $(dir ~/$*)
	@[ -f ~/$* ] || ln -s $(realpath $@) ~/$*

.PHONY: links
links: $(srcfiles)

.PHONY: clean
clean:
	rm -rf $(destfiles)
