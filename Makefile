.PHONY: cluster boot
all: kuard
cluster boot: bootstrap
%:
	@ansible-playbook $*.yml

# Some kubectl alias targets
.PHONY: kuard
kuard:
	kubectl apply -f manifests/pods/$@.yml
get-%:
	kubectl get $*
show-%:
	kubectl describe $*
deploy-%:
	kubectl apply -f manifests/deploy/$*.yml
delete-%:
	kubectl delete -f manifests/deploy/$*.yml

# Some cleanup targets
.PHONY: clean
clean:
	@$(RM) *.bak *.retry .*.sw? **/.*.sw?
dist-clean: clean teardown
	sudo $(RM) -rf .ansible

# TravisCI targets
.PHONY: ci-ansible
ci-test-%: ci-ansible ci-ping-%
	ansible-playbook -vvv $*.yml \
		-i inventories/test/inventory.ini -c local -e travis_ci=true \
		-e gitsite=https://github.com/
ci-ping-%:
	ansible -vvv -m ping -i inventories/test/inventory.ini -c local $*
ci-ansible:
	git clone https://github.com/ansible/ansible .ansible
	cd .ansible \
		&& sudo pip install -r requirements.txt \
		&& sudo python setup.py install 2>&1 > /dev/null
