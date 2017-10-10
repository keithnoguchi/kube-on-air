all: master node

.PHONY: master node
master node:
	@ansible-playbook $@.yml

# those are the target primarily used by the travis CI through .travis.yml.
.PHONY: ansible ping-master ping-node test-master test-node
ansible: clean
	git clone https://github.com/ansible/ansible .ansible
	cd .ansible \
		&& sudo pip install -r requirements.txt \
		&& sudo python setup.py install 2>&1 > /dev/null

ping-master:
	ansible -vvv -m ping -i inventory.local -c local master

ping-node:
	ansible -vvv -m ping -i inventory.local -c local node

test-master: ansible ping-master
	ansible-playbook -vvv master.yml \
		-i inventory.local -c local -e travis_ci=true \
		-e gitsite=https://github.com/


test-node: ansible ping-node
	ansible-playbook -vvv node.yml \
		-i inventory.local -c local -e travis_ci=true \
		-e gitsite=https://github.com/

clean:
	sudo $(RM) -rf .ansible
	$(RM) *.bak *.retry .*.sw? **/.*.sw?
