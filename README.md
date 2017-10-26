# Kube-on-Air

[![Build Status](https://travis-ci.org/keinohguchi/kube-on-air.svg)](https://travis-ci.org/keinohguchi/kube-on-air)

Creating [kubernetes cluster] over libvirt/KVM on [Arch-on-Air]!

[Arch-on-Air]: https://github.com/keinohguchi/arch-on-air/
[Kubernetes cluster]: https://kubernetes.io/docs/getting-started-guides/scratch/

- [Topology](#topology)
- [Bootstrap](#bootstrap)
- [Deploy](#deploy)
- [Cleanup](#cleanup)
- [Teardown](#teardown)
- [Reference](#reference)

## Topology

Here is the topology I created on my air as a KVM/libvirt guests.
[kube10](files/etc/libvirt/qemu/kube10.xml) is the kubernetes master,
while both [node20](files/etc/libvirt/qemu/node20.xml) and
[node21](files/etc/libvirt/qemu/node21.xml) are the nodes.
You can add more nodes as you wish, as long as you have enough cores
on your host machine.

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

I've setup a flat linux bridge based
[network](files/etc/libvirt/qemu/network/default.xml) as the management
network, not the cluster network, just to keep the node reachability
up even if I screw up the cluster network.  And I setup
[/etc/hosts](files/etc/hosts) so that I can access those guests through
names, instead of IP address, from the air.

And the output of the `virsh list` after booting up those KVM/libvirt
guests:

```sh
$ sudo virsh list
 Id    Name                           State
----------------------------------------------------
 3     kube10                         running
 4     node20                         running
 5     node21                         running
```

I've also written [Ansible](https://ansible.com) dynamic
[inventory file](inventories/local/inventory.py), which
will pick those KVM guests dynamically and place those
in the appropriate inventory groups, `master` and `node`
respectively as you guess :), based on the host prefix.

## Bootstrap

Bootstrap the kubernetes cluster, as in [bootstrap.yml](bootstrap.yml):

```sh
$ make cluster
```

Once it's done, you can see those guests correctly configured
as the kubernetes master and nodes, with `kubectl get nodes`:

```sh
$ kubectl get nodes
NAME      STATUS    ROLES     AGE       VERSION
kube10    Ready     master    1h        v1.8.2
node20    Ready     <none>    1h        v1.8.2
node21    Ready     <none>    1h        v1.8.2
```

I'm using [weave](https://github.com/weaveworks/weave) as a
[cluster networking](https://kubernetes.io/docs/concepts/cluster-administration/networking/#how-to-achieve-this)
module, as shown in `kubectl get pod -n kube-system` output:

```sh
$ kubectl get pod -n kube-system
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
module, e.g. [calico](https://github.com/projectcalico/calico), is really
simple, as shown in my [network.yml](network.yml) playbook.

By the way, please note that `make cluster` command is not idempotent yet,
meaning it won't work if you run it multiple times.  Please run `make teardown`
before running `make cluster` if the cluster is not correctly bootstrapped.

## Deploy

Deploy the
[kuard](https://github.com/kubernetes-up-and-running/kuard/blob/master/README.md)
pod:

```sh
$ make kuard
```

## Cleanup

Cleanup the
[kuard](https://github.com/kubernetes-up-and-running/kuard/blob/master/README.md)
pod:

```sh
$ make clean-kuard
```

## Teardown

Teardown the whole cluster, as in [teardown.yml](teardown.yml):

```sh
$ make teardown
```

## Reference

- [Kubernetes: Up and Running](http://shop.oreilly.com/product/0636920043874.do)
  by HB&B
- [kuard: Kubernetes Up And Running Deamon](https://github.com/kubernetes-up-and-running/kuard/blob/master/README.md)
- [Kubernetes Cluster Networking Design](https://git.k8s.io/community/contributors/design-proposals/network/networking.md)

Happy Hacking!
