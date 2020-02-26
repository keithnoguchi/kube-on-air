# SPDX-License-Identifier: GPL-2.0
SUDO ?= sudo
all: cluster test
# ansible-playbook alias
%:
	@ansible-playbook $*.yml -e latest=true -e build=true

# http://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/
.PHONY: test clean-test
test:
	@kubectl create -f https://raw.githubusercontent.com/cilium/cilium/1.6.5/examples/kubernetes/connectivity-check/connectivity-check.yaml
clean-test:
	@-kubectl delete -f https://raw.githubusercontent.com/cilium/cilium/1.6.5/examples/kubernetes/connectivity-check/connectivity-check.yaml

.PHONY: clean dist-clean list ls
clean:
	@-ansible-playbook teardown.yml
dist-clean: clean
	@$(RM) *.bak *.retry .*.sw? **/.*.sw?
	$(SUDO) $(RM) -rf .ansible
list ls:
	@$(SUDO) virsh net-list
	@$(SUDO) virsh list

# kubectl aliases
po/%:
	@kubectl create -f manifests/po/$*.yml
svc/%:
	@kubectl create -f manifests/svc/$*.yml
deploy/%:
	@kubectl create -f manifests/deploy/$*.yml
ss/%:
	@kubectl create -f manifests/ss/$*.yml
ds/%:
	@kubectl create -f manifests/ds/$*.yml
clean-po/%:
	@kubectl delete -f manifests/po/$*.yml
clean-svc/%:
	@kubectl delete -f manifests/svc/$*.yml
clean-deploy/%:
	@kubectl delete -f manifests/deploy/$*.yml
clean-ss/%:
	@kubectl delete -f manifests/ss/$*.yml
clean-ds/%:
	@kubectl delete -f manifests/ds/$*.yml

# CI targets
.PHONY: ansible
ci-test-%: ci-ping-%
	ansible-playbook -vvv $*.yml \
		-i inventory.yml -c local -e ci=true -e build=true \
		-e network=true -e gitsite=https://github.com/
ci-ping-%:
	ansible -vvv -m ping -i inventory.yml -c local $*
ansible:
	git clone https://github.com/ansible/ansible .ansible
	cd .ansible \
		&& $(SUDO) pip install -r requirements.txt \
		&& $(SUDO) python setup.py install 2>&1 > /dev/null
