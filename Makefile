# SPDX-License-Identifier: GPL-2.0
SUDO ?= sudo
all: cluster test
# ansible-playbook alias
%:
	@ansible-playbook $*.yaml -e latest=true -e build=true

# http://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/
.PHONY: test clean-test
test:
	@kubectl create -f https://raw.githubusercontent.com/cilium/cilium/1.6.6/examples/kubernetes/connectivity-check/connectivity-check.yaml
clean-test:
	@-kubectl delete -f https://raw.githubusercontent.com/cilium/cilium/1.6.6/examples/kubernetes/connectivity-check/connectivity-check.yaml

.PHONY: clean dist-clean list ls
clean: clean-hello-go clean-linkerd clean-ingress-nginx clean-metallb
	@-ansible-playbook teardown.yaml
dist-clean: clean
	@$(RM) *.bak *.retry .*.sw? **/.*.sw?
	$(SUDO) $(RM) -rf .ansible
list ls:
	@$(SUDO) virsh net-list
	@$(SUDO) virsh list
	@docker images

# helm based install/uninstall
install-%:
	@helm install $* charts/$*
uninstall-%:
	@helm uninstall $*

# NodePort based ingress-nginx
.PHONY: ingress-nginx clean-ingress-nginx
ingress-nginx:
	@kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/mandatory.yaml
	@kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/provider/baremetal/service-nodeport.yaml
clean-ingress-nginx:
	@-kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/provider/baremetal/service-nodeport.yaml
	@-kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/mandatory.yaml

# simple hello app
.PHONY: clean-hello-go
hello-%:
	@cd examples/hello && docker build -f Dockerfile.hello-go \
		-t host.local:5000/hello-$*:latest .
push-hello-%: hello-%
	@docker push host.local:5000/hello-$*:latest
clean-hello-go:
	@-docker rmi host.local:5000/hello-go
	@-cd examples/hello && go clean

# prometheus
.PHONY: prom clean-prom
prom: cm/prometheus deploy/prometheus
clean-prom: clean-deploy/prometheus clean-cm/prometheus

# linkerd
.PHONY: linkerd clean-linkerd cat-linkerd ls-linkerd test-linkerd
linkerd:
	@curl -sL https://run.linkerd.io/install | sh
	@linkerd install | kubectl apply -f -
clean-linkerd:
	@-curl -sL https://run.linkerd.io/emojivoto.yml| kubectl delete -f -
	@-linkerd install --ignore-cluster | kubectl delete -f -
cat-linkerd:
	@linkerd install --ignore-cluster | less
ls-linkerd:
	@kubectl get -o wide -n linkerd po
test-linkerd:
	@curl -sL https://run.linkerd.io/emojivoto.yml | kubectl apply -f -
linkerd-%:
	@linkerd $*

# metallb software load balancer
.PHONY: metallb clean-metallb
metallb:
	@kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.8.3/manifests/metallb.yaml
clean-metallb:
	@-kubectl delete -f https://raw.githubusercontent.com/google/metallb/v0.8.3/manifests/metallb.yaml

# kubectl aliases
.PHONY: dashboard
dashboard:
	@kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-rc5/aio/deploy/recommended.yaml
po/%:
	@kubectl create -f manifests/po/$*.yaml
svc/%:
	@kubectl create -f manifests/svc/$*.yaml
deploy/%:
	@kubectl create -f manifests/deploy/$*.yaml
ss/%:
	@kubectl create -f manifests/ss/$*.yaml
ds/%:
	@kubectl create -f manifests/ds/$*.yaml
cm/%:
	@kubectl create -f manifests/cm/$*.yaml
ing/%:
	@kubectl create -f manifests/ing/$*.yaml
clean-po/%:
	@-kubectl delete -f manifests/po/$*.yaml
clean-svc/%:
	@-kubectl delete -f manifests/svc/$*.yaml
clean-deploy/%:
	@-kubectl delete -f manifests/deploy/$*.yaml
clean-ss/%:
	@-kubectl delete -f manifests/ss/$*.yaml
clean-ds/%:
	@-kubectl delete -f manifests/ds/$*.yaml
clean-cm/%:
	@-kubectl delete -f manifests/cm/$*.yaml
clean-ing/%:
	@-kubectl delete -f manifests/ing/$*.yaml

# CI targets
.PHONY: ansible
ci-%: ci-ping-%
	ansible-playbook -vvv $*.yaml \
		-i inventory.yaml -c local -e ci=true -e build=true \
		-e network=true -e gitsite=https://github.com/
ci-hello-go: hello-go
ci-ping-%:
	ansible -vvv -m ping -i inventory.yaml -c local $*
ansible:
	git clone https://github.com/ansible/ansible .ansible
	cd .ansible \
		&& $(SUDO) pip install -r requirements.txt \
		&& $(SUDO) python setup.py install 2>&1 > /dev/null
