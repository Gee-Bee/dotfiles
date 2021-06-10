srcfiles := $(shell find home -type f)
destfiles := $(patsubst home/%,~/%,$(srcfiles))

.PHONY: all
all: links chmod

home/%:
	@[ -d $(dir ~/$*) ] || mkdir -p $(dir ~/$*)
	@[ -f ~/$* ] || ln -s $(realpath $@) ~/$*

.PHONY: links
links: $(srcfiles)

.PHONY: chmod
chmod:
	chmod +x home/bin/*

.PHONY: setup
setup: fedora_setup code_extensions

.PHONY: fedora_setup
fedora_setup:
	sudo ./fedora_setup

.PHONY: code_extensions
code_extensions:
	./code_extensions

.PHONY: zprezto
zprezto:
	sudo dnf install -y zsh git
	git clone --recursive git@github.com:Gee-Bee/prezto.git ~/.zprezto
	make -C ~/.zprezto
	chsh -s /bin/zsh

.PHONY: bash-it
bash-it:
	git clone --depth=1 https://github.com/Bash-it/bash-it.git ~/.bash_it
	git clone git@github.com:Gee-Bee/bash-it-custom.git ~/bash_it/custom
	~/.bash_it/install.sh

.PHONY: clean
clean:
	rm -rf $(destfiles)
