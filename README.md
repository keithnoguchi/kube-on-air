# Kube-on-Air

[![Build Status](https://travis-ci.org/keinohguchi/kube-on-air.svg)](https://travis-ci.org/keinohguchi/kube-on-air)

Creating [kubernetes cluster] over libvirt/KVM on [Arch-on-Air]!

[Arch-on-Air]: https://github.com/keinohguchi/arch-on-air/
[Kubernetes cluster]: https://kubernetes.io/docs/getting-started-guides/scratch/

## Topology

Here is the topology I created on my air as a KVM/libvirt guests.
`kube10` is the kubernetes master, while both `node20` and `node21`
is the nodes.  You can add more nodes as you wish, as long as you
have enough core on your host machine.

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

I've written [Ansible](https://ansible.com) dynamic
[inventory file](inventories/local/inventory.py) which
will pick the those KVM guests to the appropriate groups,
in `master` and `node` respectively, as you guess. :)

## Bootstrap

Bootstrap the kubernetes cluster!

```sh
$ make cluster
```

Currently, `make cluster` is not idempotent.  Please run `make teardown` before
running `make cluster` again.

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
