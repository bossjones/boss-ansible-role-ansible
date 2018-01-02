# include .mk

SHELL=/bin/bash

username := bossjones

# verify that certain variables have been defined off the bat
check_defined = \
    $(foreach 1,$1,$(__check_defined))
__check_defined = \
    $(if $(value $1),, \
      $(error Undefined $1$(if $(value 2), ($(strip $2)))))

list_allowed_args := name inventory

export PATH := ./bin:./venv/bin:$(PATH)

mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(notdir $(patsubst %/,%,$(dir $(mkfile_path))))

.PHONY: list help
# .PHONY: all dockerfile docker-compose test test-build lint clean pristine run run-single run-cluster build release-manager release-manager-snapshot push

# TODO: Modify this command if you want to use cookiecutter to create something from scratch again
# cookiecutter-init:
# 	cookiecutter --output-dir=./ansible-role-bossjones-ipv6 --no-input gh:retr0h/cookiecutter-molecule \
#                         full_name="Malcolm Jones" \
#                         email="bossjones@theblacktonystark.com" \
#                         role_name="bossjones.ipv6" \
#                         github_user="bossjones" \
#                         repo_name="ansible-role-bossjones-ipv6" \
#                         short_description="ansible role to install bossjones ipv6. Only works on fedora 24 currently" \
#                         release_date="2017-09-09" \
#                         year="2017" \
#                         version="0.1.0" \
#                         min_ansible_version="2.3.2.0" \
#                         allow_duplicates="no" \
#                         scenario_name="default" \
#                         author="Malcolm Jones" \
#                         description="ansible role to install bossjones ipv6. Only works on fedora 24 currently" \
#                         company="Tony Dark Labs" \
#                         license="Apache"

bootstrap-molecule-default:
	molecule init scenario --role-name $(current_dir) --scenario-name default

ci:
	molecule test

# NOTE: make this into a bash alias (pretty-yaml)
pretty-yaml:
	python -m pyaml /path/to/some/file.yaml

help:
	@echo "Convenience Make commands for provisioning a scarlett node"

list:
	@$(MAKE) -qp | awk -F':' '/^[a-zA-Z0-9][^$#\/\t=]*:([^=]|$$)/ {split($$1,A,/ /);for(i in A)print A[i]}' | sort

vagrant-provision:
	vagrant provision

vagrant-up:
	vagrant up

vagrant-ssh:
	vagrant ssh

vagrant-destroy:
	vagrant destroy

vagrant-halt:
	vagrant halt

vagrant-config:
	vagrant ssh-config

serverspec:
	bundle exec rake

serverspec-install:
	bundle install --path .vendor

download-roles:
	ansible-galaxy install -r install_roles.txt --roles-path roles/ -vvv

install-cidr-brew:
	pip install cidr-brewer

install-test-deps:
	pip install ansible==2.2.3.0
	pip install docker-py
	pip install molecule --pre

ci:
	molecule test

bootstrap: venv

# enter virtualenv so we can use Ansible
activate:
	. venv/bin/activate

# The tests are written in Python. Make a virtualenv to handle the dependencies.
venv: requirements.txt
	@if [ -z $$PYTHON2 ]; then\
	    PY2_MINOR_VER=`python2 --version 2>&1 | cut -d " " -f 2 | cut -d "." -f 2`;\
	    if (( $$PY2_MINOR_VER < 7 )); then\
		echo "Couldn't find python2 in \$PATH that is >=3.5";\
		echo "Please install python2.7 or later or explicity define the python3 executable name with \$PYTHON2";\
	        echo "Exiting here";\
	        exit 1;\
	    else\
		export PYTHON2="python2.$$PY2_MINOR_VER";\
	    fi;\
	fi;\
	test -d venv || virtualenv --python=$$PYTHON2 venv;\
	pip install -r requirements.txt;\
	pip install -r requirements-dev.txt;\
	touch venv;\

# [ANSIBLE0013] Use shell only when shell functionality is required
ansible-lint-role:
	bash -c "find .* -type f -name '*.y*ml' -print0 | xargs -I FILE -t -0 -n1 ansible-lint -x ANSIBLE0006,ANSIBLE0007,ANSIBLE0010,ANSIBLE0013 FILE"

yamllint-role:
	bash -c "find .* -type f -name '*.y*ml' -print0 | xargs -I FILE -t -0 -n1 yamllint FILE"

ping:
	$(call check_defined, inventory, Please set inventory)
	@ansible-playbook -i $(inventory) ping.yml

# SOURCE: https://medium.com/@shredder/using-ansible-tags-with-vagrant-provision-a4856966a987
# EXAMPLE: ansible-playbook -i inventory —private-key=~/.vagrant.d/insecure_private_key -u vagrant playbook.yml —tags=”phpconf”
run-playbook:
	echo "running playbook"
