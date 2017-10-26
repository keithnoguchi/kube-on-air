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

Bootstrap the kubernetes cluster!

```sh
$ make cluster
```

Once it's done, you can get those three nodes through `kubectl`
as below:

```sh
$ kubectl get node
NAME      STATUS    ROLES     AGE       VERSION
kube10    Ready     master    1h        v1.8.2
node20    Ready     <none>    1h        v1.8.2
node21    Ready     <none>    1h        v1.8.2
```

Note that currently, `make cluster` is not idempotent, meaning
you can't run `make cluster` multiple times without the side effect.

Please run `make teardown` before running `make cluster` again.

## Deploy

Deply the pods.

```sh
$ make kuard
```

## Cleanup

Cleanup the pods.

```sh
$ make clean-kuard
```

## Teardown

Teardown the cluster!

```sh
$ make teardown
```

## Reference

- [Kubernetes: Up and Running](http://shop.oreilly.com/product/0636920043874.do)
  by HB&B

Happy Hacking!
