# Kube-on-Air

[![CircleCI]](https://circleci.com/gh/keithnoguchi/workflows/kube-on-air)

[CircleCI]: https://circleci.com/gh/keithnoguchi/kube-on-air.svg?style=svg

Creating [Kubernetes Cluster] with [KVM/libvirt] on [Arch-on-Air]!

- [Topology](#topology)
- [Bootstrap](#bootstrap)
- [Deploy](#deploy)
- [Test](#test)
- [Cleanup](#cleanup)
- [Teardown](#teardown)
- [References](#references)

[kvm/libvirt]: https://libvirt.org/drvqemu.html
[arch-on-air]: https://github.com/keithnoguchi/arch-on-air/blob/master/README.md
[asciicast]: https://asciinema.org/a/146661.png

## Topology

Here is the topology I created on my air as a KVM/libvirt guests.
[head10] template file is for the kubernetes master, while [work11]
one is for the nodes.  You can add more nodes as you wish, as long
as you have enough cores on your host machine.

[head10]: templates/etc/libvirt/qemu/head.xml.j2
[work11]: templates/etc/libvirt/qemu/work.xml.j2

```
 +----------+ +-----------+ +------------+ +------------+
 |  head10  | |   work11  | |   work12   | |   work13   |
 | (master) | |  (worker) | |  (worker)  | |  (worker)  |
 +----+-----+ +-----+-----+ +-----+------+ +-----+------+
      |             |             |              |
+-----+-------------+-------------+--------------+-------+
|                        air                             |
|                 (KVM/libvirt host)                     |
+--------------------------------------------------------+
```

I've setup a flat linux bridge based [network] as the management
network, not the cluster network, just to keep the node reachability
up even if I screw up the cluster network.  And I setup [/etc/hosts]
so that I can access those guests through names, instead of IP address,
from the air.

[network]: files/etc/libvirt/qemu/network/default.xml
[/etc/hosts]: files/etc/hosts

And the output of the `virsh list` after booting up those KVM/libvirt
guests:

```sh
$ make ls
 Name      State    Autostart   Persistent
--------------------------------------------
 default   active   no          yes

 Id   Name     State
------------------------
 6    head10   running
 7    work11   running
 8    work12   running
 9    work13   running
```

I've also written [Ansible] dynamic [inventory file],
which will pick those KVM guests dynamically and
place those in the appropriate inventory groups,
`master` and `node` respectively as you guess :),
based on the host prefix.

[Ansible]: https://ansible.com
[inventory file]: inventory.py

## Bootstrap

Bootstrap the kubernetes cluster, as in [cluster.yaml]:

```sh
$ make cluster
```

Once it's done, you can see those guests correctly configured
as the kubernetes master and nodes, with `kubectl get nodes`:

```sh
$ kubectl get node -o wide
NAME     STATUS   ROLES    AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE     KERNEL-VERSION   C
ONTAINER-RUNTIME
head10   Ready    master   46s   v1.17.2   172.31.255.10   <none>        Arch Linux   5.4.6-arch3-1    d
ocker://19.3.5
work11   Ready    <none>   13s   v1.17.2   172.31.255.11   <none>        Arch Linux   5.4.6-arch3-1    d
ocker://19.3.5
work12   Ready    <none>   14s   v1.17.2   172.31.255.12   <none>        Arch Linux   5.4.6-arch3-1    d
ocker://19.3.5
work13   Ready    <none>   14s   v1.17.2   172.31.255.13   <none>        Arch Linux   5.4.6-arch3-1    d
ocker://19.3.5
```

I'm using [kube-router] as the [kubernetes cluster networking] module, as shown in
`kubectl get pod -n kube-system` output:

```sh
$ kubectl get pod -n kube-system -o wide
NAME                             READY   STATUS    RESTARTS   AGE     IP              NODE     NOMINATED NODE   READINESS GATES
coredns-684f7f6cb4-g4j89         1/1     Running   0          5m24s   10.244.1.3      work12   <none>           <none>
coredns-684f7f6cb4-tnhdw         1/1     Running   0          5m24s   10.244.3.2      work13   <none>           <none>
etcd-head10                      1/1     Running   0          5m38s   172.31.255.10   head10   <none>           <none>
kube-apiserver-head10            1/1     Running   0          5m38s   172.31.255.10   head10   <none>           <none>
kube-controller-manager-head10   1/1     Running   0          5m38s   172.31.255.10   head10   <none>           <none>
kube-proxy-bv4vj                 1/1     Running   0          5m24s   172.31.255.10   head10   <none>           <none>
kube-proxy-h5spx                 1/1     Running   0          5m10s   172.31.255.11   work11   <none>           <none>
kube-proxy-h6h8l                 1/1     Running   0          5m10s   172.31.255.13   work13   <none>           <none>
kube-proxy-tc7r7                 1/1     Running   0          5m10s   172.31.255.12   work12   <none>           <none>
kube-router-5w9lc                1/1     Running   0          5m7s    172.31.255.13   work13   <none>           <none>
kube-router-fd584                1/1     Running   0          5m7s    172.31.255.10   head10   <none>           <none>
kube-router-lnslj                1/1     Running   0          5m7s    172.31.255.12   work12   <none>           <none>
kube-router-vzsv6                1/1     Running   0          5m7s    172.31.255.11   work11   <none>           <none>
kube-scheduler-head10            1/1     Running   0          5m38s   172.31.255.10   head10   <none>           <none>
```

And, thanks to k8s super clean modular approach, changing it to other
module, e.g. [calico], is really simple, as shown in my [network.yaml] playbook.

By the way, please note that `make cluster` command is not idempotent yet,
meaning it won't work if you run it multiple times.  Please run `make teardown`
before running `make cluster` if the cluster is not correctly bootstrapped.

## Deploy

### Pods

Deploy the [kuard] pod:

```sh
air$ make po/kuard
```

You can check the kuard pod state transition with `kubectl get pod --watch` command:

```sh
air$ kubectl get pod --watch
NAME      READY     STATUS    RESTARTS   AGE
kuard     0/1       Pending   0          6s
kuard     0/1       Pending   0         6s
kuard     0/1       ContainerCreating   0         6s
kuard     0/1       Running   0         7s
kuard     1/1       Running   0         38s
```

### Deployment

You can deploy [dnstools] container on all the nodes through the `Deployment` manifest, as in [dnstools.yaml]:

```sh
$ make deploy/dnstools
```

You can check if `dnstools` pods are up and running as below:

```sh
$ kubectl get deploy -o wide -w
NAME       READY   UP-TO-DATE   AVAILABLE   AGE     CONTAINERS   IMAGES              SELECTOR
dnstools   3/3     3            3           4m35s   dnstools     infoblox/dnstools   app=dnstools
```

### Ingress

Let's access containers through [nginx ingress controller].

First setup the controller with `make ingress-nginx`:

```sh
$ make ingress-nginx
```

You can check resources through `kubectl`:

```sh
$ kubectl -n ingress-nginx get all
NAME                                            READY   STATUS    RESTARTS   AGE
pod/nginx-ingress-controller-7f74f657bd-k7j7v   1/1     Running   0          36m

NAME                    TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)
           AGE
service/ingress-nginx   NodePort   10.108.220.67   <none>        80:30724/TCP,443:32697/TCP   36m

NAME                                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx-ingress-controller   1/1     1            1           36m

NAME                                                  DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-ingress-controller-7f74f657bd   1         1         1       36m
```

Now, let's create a fanout example with `make ing/fanout` command:

```sh
$ make ing/fanout
```

Check it with the `kubectl describe ing/fanout`:

```sh
$ kubectl describe ing/fanout
Name:             fanout
Namespace:        default
Address:          10.108.220.67
Default backend:  default-http-backend:80 (<error: endpoints "default-http-backend" not found>)
Rules:
  Host        Path  Backends
  ----        ----  --------
  *
              /apple    apples:5678 (10.244.1.16:5678,10.244.1.18:5678)
              /banana   bananas:5678 (10.244.1.17:5678)
Annotations:  nginx.ingress.kubernetes.io/rewrite-target: /
Events:
  Type    Reason  Age   From                      Message
  ----    ------  ----  ----                      -------
  Normal  CREATE  10m   nginx-ingress-controller  Ingress default/fanout
  Normal  UPDATE  9m5s  nginx-ingress-controller  Ingress default/fanout
```

Now, check the `ingress-nginx-controller`'s node port with `kubectl`:

```sh
$ kubectl -n ingress-nginx get svc
NAME            TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)
   AGE
ingress-nginx   NodePort   10.108.220.67   <none>        80:30724/TCP,443:32697/TCP   39m
```

and check the node IP with `kubectl get node`:

```sh
$ kubectl get node -o wide
NAME     STATUS   ROLES    AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE
   KERNEL-VERSION   CONTAINER-RUNTIME
head10   Ready    master   47m   v1.17.3   172.31.255.10   <none>        Arch Linux   5.5.7-arch1-1    docker://19.3.6
work11   Ready    <none>   47m   v1.17.3   172.31.255.11   <none>        Arch Linux   5.5.7-arch1-1    docker://19.3.6
work12   Ready    <none>   47m   v1.17.3   172.31.255.12   <none>        Arch Linux   5.5.7-arch1-1    docker://19.3.6
work13   Ready    <none>   47m   v1.17.3   172.31.255.13   <none>        Arch Linux   5.5.7-arch1-1    docker://19.3.6
```

Pick one of those and run curl to get the result:

```sh
$ curl http://172.31.255.13:30724/apple
apple
$ curl http://172.31.255.13:30724/banana
banan
```

Make sure you get 404 when you access other path.

```sh
$ curl http://172.31.255.13:30724/
<html>
<head><title>404 Not Found</title></head>
<body>
<center><h1>404 Not Found</h1></center>
<hr><center>nginx/1.17.8</center>
</body>
</html>
```

## Test

I've incorporated [Cilium]'s [connectivity check test] as below:

```sh
$ make test
deployment.apps/probe created
service/echo created
deployment.apps/echo created
```

You should be able to get all the pods up and running as shown below:

```sh
$ kubectl get po -o wide
NAME                     READY   STATUS    RESTARTS   AGE   IP           NODE     NOMINATED NODE   READINESS GATES
echo-5659cf6c69-56t47    1/1     Running   0          19s   10.244.1.4   work11   <none>           <none>
echo-5659cf6c69-c5ngd    1/1     Running   0          19s   10.244.2.5   work13   <none>           <none>
echo-5659cf6c69-j6nk2    1/1     Running   0          19s   10.244.1.5   work11   <none>           <none>
echo-5659cf6c69-sz2kw    1/1     Running   0          19s   10.244.2.4   work13   <none>           <none>
echo-5659cf6c69-z7xvp    1/1     Running   0          19s   10.244.3.5   work12   <none>           <none>
probe-765cbd6789-dshtf   1/1     Running   0          19s   10.244.1.3   work11   <none>           <none>
probe-765cbd6789-qggtr   1/1     Running   0          19s   10.244.3.4   work12   <none>           <none>
probe-765cbd6789-qrpwd   1/1     Running   0          19s   10.244.2.3   work13   <none>           <none>
probe-765cbd6789-x6f6h   1/1     Running   0          19s   10.244.2.2   work13   <none>           <none>
probe-765cbd6789-x86x6   1/1     Running   0          19s   10.244.3.3   work12   <none>           <none>
```

[cilium]: http://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/
[connectivity check test]: https://raw.githubusercontent.com/cilium/cilium/1.6.6/examples/kubernetes/connectivity-check/connectivity-check.yaml

## Cleanup

### Pods

Cleanup the [kuard] pod:

```sh
air$ make clean-po/kuard
```

## Teardown

Teardown the whole cluster, as in [teardown.yaml]:

```sh
air$ make clean
```

### Ansible playbooks

Here is the list of [Ansible] playbooks used in this project:

- [host.yaml]: KVM/libvirt host playbook
- [cluster.yaml]: Cluster playbook
  - [build.yaml]: k8s Build playbook
  - [head.yaml]: Head node playbook
  - [work.yaml]: Worker node playbook
  - [network.yaml]: Network/CNI playbook
- [teardown.yaml]: Teardown playbook

[host.yaml]: host.yaml
[cluster.yaml]: cluster.yaml
[build.yaml]: build.yaml
[head.yaml]: head.yaml
[work.yaml]: work.yaml
[network.yaml]: network.yaml
[teardown.yaml]: teardown.yaml

## References

- [Kubernetes: Up and Running] by HB&B
  - [kuard]: Kubernetes Up And Running Daemon
- How to create [Kubernetes Cluster] from scratch
  - [kubelet]: What even is a kubelet? by [Kamal Marhubi]
  - [kube-apiserver]: Kubernetes from the ground up: the API server by [Kamal Marhubi]
  - [kube-scheduler]: Kubernetes from the ground up: the scheduler by [Kamal Marhubi]
- [Kubernetes networking]
  - [Kubernetes Cluster Networking] Concepts
  - [Kubernetes Cluster Networking Design]
  - [CNI]: Container Network Interface Specification
  - [bash-cni-plugin]: Command line based CNI plugin
  - [How to inspect k8s networking]
  - [kube-router]
    - [kube-router blog posts]
    - [kube-router user guide]
    - [kube-router with kubeadm]: Deploying kube-router with kubeadm
  - [kube with cilium]
- [Ingress Controllers]
  - [What is Ingress?]
  - [Nginx ingress controller]
    - [How it works]
    - [Bare-metal consideration]
      - [MetalLB]
    - [Nginx ingress guide]
- [Linkerd]: Ultralight service mesh for Kubernetes and beyond
  - [Linkerd getting started]
- [Kafka]
  - [Getting started with Kafka on Kube]
  - [Kafka stack on Kube (YouTube)]
  - [Kafka on Kube, Could you, Should you]

[kubernetes: up and running]: http://shop.oreilly.com/product/0636920043874.do
[kuard]: https://github.com/kubernetes-up-and-running/kuard/blob/master/README.md
[kubernetes cluster]: https://kubernetes.io/docs/getting-started-guides/scratch/
[Kamal Marhubi]: http://kamalmarhubi.com/
[kubelet]: http://kamalmarhubi.com/blog/2015/08/27/what-even-is-a-kubelet/
[kube-apiserver]: http://kamalmarhubi.com/blog/2015/09/06/kubernetes-from-the-ground-up-the-api-server/
[kube-scheduler]: http://kamalmarhubi.com/blog/2015/11/17/kubernetes-from-the-ground-up-the-scheduler/
[kubernetes networking]: https://www.altoros.com/blog/kubernetes-networking-writing-your-own-simple-cni-plug-in-with-bash/
[kubernetes cluster networking]: https://kubernetes.io/docs/concepts/cluster-administration/networking/
[kubernetes cluster networking design]: https://git.k8s.io/community/contributors/design-proposals/network/networking.md
[cni]: https://github.com/containernetworking/cni/blob/master/SPEC.md
[bash-cni-plugin]: https://github.com/s-matyukevich/bash-cni-plugin
[how to inspect k8s networking]: https://www.digitalocean.com/community/tutorials/how-to-inspect-kubernetes-networking
[kube-router]: https://www.kube-router.io/
[kube-router blog posts]: https://cloudnativelabs.github.io/post/2017-04-18-kubernetes-networking/
[kube-router user guide]: https://www.kube-router.io/docs/user-guide/
[kube-router with kubeadm]: https://github.com/cloudnativelabs/kube-router/blob/master/docs/kubeadm.md
[kube with cilium]: http://virtualelephant.com/2020/03/24/kubernetes-with-cilium-p1/
[ingress controllers]: https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/
[what is ingress?]: https://kubernetes.io/docs/concepts/services-networking/ingress/
[nginx ingress controller]: https://kubernetes.github.io/ingress-nginx/
[how it works]: https://kubernetes.github.io/ingress-nginx/how-it-works/
[bare-metal consideration]: https://kubernetes.github.io/ingress-nginx/deploy/baremetal/
[metallb]: https://metallb.universe.tf/
[nginx ingress guide]: https://matthewpalmer.net/kubernetes-app-developer/articles/kubernetes-ingress-guide-nginx-example.html
[linkerd]: https://linkerd.io/
[linkerd getting started]: https://linkerd.io/2/getting-started/
[kafka]: http://kafka.apache.org/
[getting started with kafka on kube]: https://www.confluent.io/blog/getting-started-apache-kafka-kubernetes
[Kafka stack on kube (youtube)]: https://www.youtube.com/watch?v=P_DEreC4ECw
[kafka on kube, could you, should you]: https://www.confluent.io/blog/apache-kafka-kubernetes-could-you-should-you/

Happy Hacking!
