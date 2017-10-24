# Kube-on-Air

[![Build Status](https://travis-ci.org/keinohguchi/kube-on-air.svg)](https://travis-ci.org/keinohguchi/kube-on-air)

Creating [kubernetes cluster] over libvirt/KVM on [Arch-on-Air]!

[Arch-on-Air]: https://github.com/keinohguchi/arch-on-air/
[Kubernetes cluster]: https://kubernetes.io/docs/getting-started-guides/scratch/

## Bootstrap

Bootstrap the kubernetes cluster!

```sh
$ make cluster
```

Note that there are some hardcoded variables, cluster APIs etc, which will
be templated soon.

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
