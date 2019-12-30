# SPDX-License-Identifier: GPL-2.0
SUDO ?= sudo
.PHONY: all list
all: clean cluster-latest test
list:
	@$(SUDO) virsh net-list
	@$(SUDO) virsh list
%:
	@ansible-playbook $*.yml -e latest=false -e full=false
%-latest:
	@ansible-playbook $*.yml -e latest=true -e full=false
%-full:
	@ansible-playbook $*.yml -e latest=true -e full=true
%-pod:
	@kubectl create -f manifests/po/$*.yml
%-svc:
	@kubectl create -f manifests/svc/$*.yml
%-deploy:
	@kubectl create -f manifests/deploy/$*.yml
%-ss:
	@kubectl create -f manifests/statefulset/$*.yml
clean-%-pod:
	@kubectl delete -f manifests/po/$*.yml
clean-%-svc:
	@kubectl delete -f manifests/svc/$*.yml
clean-%-deploy:
	@kubectl delete -f manifests/deploy/$*.yml
clean-%-ss:
	@kubectl delete -f manifests/statefulset/$*.yml
# http://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/
.PHONY: test clean-test
test:
	@kubectl create -f https://raw.githubusercontent.com/cilium/cilium/1.6.5/examples/kubernetes/connectivity-check/connectivity-check.yaml
clean-test:
	@-kubectl delete -f https://raw.githubusercontent.com/cilium/cilium/1.6.5/examples/kubernetes/connectivity-check/connectivity-check.yaml

# Some cleanup targets
.PHONY: clean dist-clean
clean:
	@-ansible-playbook teardown.yml
dist-clean: clean
	@$(RM) *.bak *.retry .*.sw? **/.*.sw?
	$(SUDO) $(RM) -rf .ansible

# CI targets
.PHONY: ci-ansible
ci-test-%: ci-ping-%
	ansible-playbook -vvv $*.yml \
		-i inventory.yml -c local -e ci=true -e latest=true \
		-e full=false -e gitsite=https://github.com/
ci-ping-%:
	ansible -vvv -m ping -i inventory.yml -c local $*
ci-ansible:
	git clone https://github.com/ansible/ansible .ansible
	cd .ansible \
		&& $(SUDO) pip install -r requirements.txt \
		&& $(SUDO) python setup.py install 2>&1 > /dev/null
