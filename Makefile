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

define updateOnShutdownService
[Unit]
Description=Install updates on shutdown
DefaultDependencies=false
Before=shutdown.target

[Service]
Type=oneshot
ExecStart=/usr/bin/dnf upgrade -y --cacheonly
RemainAfterExit=yes

[Install]
WantedBy=shutdown.target
endef
export updateOnShutdownService
.PHONY: fedora_autoupdate
fedora_autoupdate:
	sudo dnf install -y dnf-automatic
	sudo systemctl enable --now dnf-automatic.timer
	@echo "$$updateOnShutdownService" | sudo tee /etc/systemd/system/update-on-shutdown.service
	sudo systemctl enable update-on-shutdown.service

.PHONY: fedora_autoupdate_disable
fedora_autoupdate_disable:
	sudo systemctl disable dnf-automatic.timer
	sudo systemctl disable update-on-shutdown.service
	sudo rm -f /etc/systemd/system/update-on-shutdown.service

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
	rm -rf ~/.bash_it/custom
	git clone git@github.com:Gee-Bee/bash-it-custom.git ~/.bash_it/custom
	~/.bash_it/install.sh
	echo 'eval "$(starship init bash)"' >> ~/.bashrc

.PHONY: clean
clean:
	rm -rf $(destfiles)
