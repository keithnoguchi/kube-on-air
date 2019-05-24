# Kube-on-Air

[![CircleCI]](https://circleci.com/gh/keinohguchi/workflows/kube-on-air)

[CircleCI]: https://circleci.com/gh/keinohguchi/kube-on-air.svg?style=svg

Creating [Kubernetes Cluster] over [KVM/libvirt] on [Arch-on-Air]!

- [Topology](#topology)
- [Bootstrap](#bootstrap)
- [Deploy](#deploy)
- [Cleanup](#cleanup)
- [Teardown](#teardown)
- [Reference](#reference)

[![asciicast]](https://asciinema.org/a/146661)

[KVM/libvirt]: https://libvirt.org/drvqemu.html
[Arch-on-Air]: https://github.com/keinohguchi/arch-on-air/blob/master/README.md
[asciicast]: https://asciinema.org/a/146661.png

## Topology

Here is the topology I created on my air as a KVM/libvirt guests.
[kube10] template file is for the kubernetes master, while [node20]
one is for the nodes.  You can add more nodes as you wish, as long
as you have enough cores on your host machine.

[kube10]: templates/etc/libvirt/qemu/kube.xml.j2
[node20]: templates/etc/libvirt/qemu/node.xml.j2

```
                     +----------+
                     |  kube10  |
                     | (master) |
                     +----+-----+
                          |
         +-----------+    |     +------------+
         |   node20  |    |     |   node21   |
         |   (node)  |    |     |   (node)   |
         +-----+-----+    |     +-----+------+
               |          |           |
+--------------+----------+-----------+----------------+
|                        air                           |
|                 (KVM/libvirt host)                   |
+------------------------------------------------------+
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
air$ sudo virsh list
 Id    Name                           State
----------------------------------------------------
 3     kube10                         running
 4     node20                         running
 5     node21                         running
```

I've also written [Ansible] dynamic [inventory file],
which will pick those KVM guests dynamically and
place those in the appropriate inventory groups,
`master` and `node` respectively as you guess :),
based on the host prefix.

[Ansible]: https://ansible.com
[inventory file]: inventory.py

## Bootstrap

Bootstrap the kubernetes cluster, as in [cluster.yml]:

```sh
air$ make cluster
```

Once it's done, you can see those guests correctly configured
as the kubernetes master and nodes, with `kubectl get nodes`:

```sh
air$ kubectl get node
NAME      STATUS    ROLES     AGE       VERSION
kube10    Ready     master    1h        v1.8.2
node20    Ready     <none>    1h        v1.8.2
node21    Ready     <none>    1h        v1.8.2
```

I'm using [weave] as a [kubernetes cluster networking] module, as shown in
`kubectl get pod -n kube-system` output:

```sh
air$ kubectl get pod -n kube-system
NAME                             READY     STATUS    RESTARTS   AGE
etcd-kube10                      1/1       Running   0          13m
kube-apiserver-kube10            1/1       Running   0          13m
kube-controller-manager-kube10   1/1       Running   0          13m
kube-dns-545bc4bfd4-95dt7        3/3       Running   0          14m
kube-proxy-b9227                 1/1       Running   0          14m
kube-proxy-ndfrc                 1/1       Running   0          14m
kube-proxy-wnm9n                 1/1       Running   0          14m
kube-scheduler-kube10            1/1       Running   0          13m
weave-net-fzznm                  2/2       Running   0          14m
weave-net-xqqhc                  2/2       Running   0          14m
weave-net-zgh8z                  2/2       Running   0          14m
```

And, thanks to k8s super clean modulality approach, changing it to other
module, e.g. [calico], is really simple, as shown in my [network.yml] playbook.

By the way, please note that `make cluster` command is not idempotent yet,
meaning it won't work if you run it multiple times.  Please run `make teardown`
before running `make cluster` if the cluster is not correctly bootstrapped.

## Deploy

### Pods

Deploy the [kuard] pod:

```sh
air$ make kuard
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

### DaemonSets

You can deploy [fluentd] container on all the nodes through the `DaemonSet` manifest, as in [fluentd.yml]:

```sh
air$ kubectl apply -f manifests/ds/fluentd.yml
```

You can watch if the `fluentd` up and running in the `kube-system` namespace
by adding `-n kube-system` command line option, as below:

```sh
air$ kubectl get pod -n kube-system -l app=fluentd -o wide --watch
NAME            READY     STATUS    RESTARTS   AGE       IP        NODE
fluentd-nvwk5   0/1       Pending   0          6s        <none>    node21
fluentd-thqvw   0/1       Pending   0         6s        <none>    node20
fluentd-nvwk5   0/1       ContainerCreating   0         6s        <none>    node21
fluentd-thqvw   0/1       ContainerCreating   0         6s        <none>    node20
fluentd-thqvw   1/1       Running   0         7s        10.40.0.2   node20
fluentd-nvwk5   1/1       Running   0         7s        10.32.0.3   node21
fluentd-thqvw   1/1       Running   0         8s        10.40.0.2   node20
fluentd-nvwk5   1/1       Running   0         8s        10.32.0.3   node21
```

## Cleanup

### Pods

Cleanup the [kuard] pod:

```sh
air$ make clean-kuard
```

## Teardown

Teardown the whole cluster, as in [teardown.yml]:

```sh
air$ make teardown
```

## Reference

- [Kubernetes: Up and Running] by HB&B
- [kuard]: Kubernetes Up And Running Daemon
- How to create [Kubernetes Cluster] from scratch
- [Kubernetes Cluster Networking] Concepts
- [Kubernetes Cluster Networking Design]
- [Weave]: A virtual network that connects Docker containers across multiple hosts
- [Calico]: An open source system enabling cloud native application connectivity and policy
- [kubelet]: What even is a kubelet? by [Kamal Marhubi]
- [kube-apiserver]: Kubernetes from the ground up: the API server by [Kamal Marhubi]
- [kube-scheduler]: Kubernetes from the ground up: the scheduler by [Kamal Marhubi]

[kubernetes: up and running]: http://shop.oreilly.com/product/0636920043874.do
[kubernetes cluster]: https://kubernetes.io/docs/getting-started-guides/scratch/
[kubernetes cluster networking]: https://kubernetes.io/docs/concepts/cluster-administration/networking/
[kubernetes cluster networking design]: https://git.k8s.io/community/contributors/design-proposals/network/networking.md
[kuard]: https://github.com/kubernetes-up-and-running/kuard/blob/master/README.md
[weave]: https://github.com/weaveworks/weave/blob/master/README.md
[calico]: https://github.com/projectcalico/calico/blob/master/README.md
[fluentd]: https://www.fluentd.org/
[Kamal Marhubi]: http://kamalmarhubi.com/
[kubelet]: http://kamalmarhubi.com/blog/2015/08/27/what-even-is-a-kubelet/
[kube-apiserver]: http://kamalmarhubi.com/blog/2015/09/06/kubernetes-from-the-ground-up-the-api-server/
[kube-scheduler]: http://kamalmarhubi.com/blog/2015/11/17/kubernetes-from-the-ground-up-the-scheduler/

### Kubernetes manifests

- [Celery RabbitMQ] kubernetes example
- [RabbitMQ StatefulSets] example

[fluentd.yml]: manifests/ds/fluentd.yml
[celery rabbitmq]: https://github.com/kubernetes/kubernetes/tree/release-1.3/examples/celery-rabbitmq/README.md
[rabbitmq statefulsets]: https://wesmorgan.svbtle.com/rabbitmq-cluster-on-kubernetes-with-statefulsets

### Ansible playbooks

Here is the list of [Ansible] playbooks used in this project:

- [host.yml]: Bootstrap the KVM/libvirt host
- [cluster.yml]: Bootstrap the kubernetes cluster
  - [master.yml]: Bootstrap kubernetes master
  - [node.yml]: Bootstrap kubernetes nodes
  - [network.yml]: Bootstrap kubernetes networking
- [teardown.yml]: Teardown the kubernetes cluster

[host.yml]: host.yml
[guest.yml]: guest.yml
[cluster.yml]: cluster.yml
[master.yml]: master.yml
[node.yml]: node.yml
[network.yml]: network.yml
[teardown.yml]: teardown.yml

Happy Hacking!
