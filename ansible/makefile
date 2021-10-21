.PHONY: all

all: setup

%:
	ansible-playbook -i inventory.yml playbooks/$@.yml
