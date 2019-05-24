SUDO ?= sudo
all: kuard

.PHONY: boot bootstrap
boot bootstrap: cluster
%:
	@ansible-playbook $*.yml -e latest=true

# https://github.com/kubernetes-up-and-running/kuard target
.PHONY: kuard
kuard:
	kubectl apply -f manifests/pods/$@.yml
clean-%:
	kubectl delete -f manifests/pods/$*.yml

# Some kubectl alias targets
get-%:
	kubectl get $*
show-%:
	kubectl describe $*
deploy-%:
	kubectl apply -f manifests/deploy/$*.yml
delete-%:
	kubectl delete -f manifests/deploy/$*.yml

# Some cleanup targets
.PHONY: clean dist-clean
clean:
	@$(RM) *.bak *.retry .*.sw? **/.*.sw?
dist-clean: clean teardown
	$(SUDO) $(RM) -rf .ansible

# TravisCI targets
.PHONY: ci-ansible
ci-test-%: ci-ansible ci-ping-%
	ansible-playbook -vvv $*.yml \
		-i inventory.yml -c local -e ci=true \
		-e latest=true -e gitsite=https://github.com/
ci-ping-%:
	ansible -vvv -m ping -i inventory.yml -c local $*
ci-ansible:
	git clone https://github.com/ansible/ansible .ansible
	cd .ansible \
		&& $(SUDO) pip install -r requirements.txt \
		&& $(SUDO) python setup.py install 2>&1 > /dev/null
