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

## Provision

```sh
$ make
```

## Deploy pod

```sh
$ make kuard
```

## Cleanup pod

```sh
$ make clean-kuard
```

## Reference

- [Kubernetes: Up and Running](http://shop.oreilly.com/product/0636920043874.do)
  by HB&B

Happy Hacking!
