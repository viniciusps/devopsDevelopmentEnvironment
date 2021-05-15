Sources:

https://gist.github.com/vfarcic/84324e2d6eb1e62e3569846a741cedea
https://github.com/mintel/vagrant-minikube

# devopsDevelopmentEnvironment

By running vagrant up, it will get you up and running with:

* Kubernetes cluster running on minikube
* ArgoCD + Argocd Cli

## Install Pre-requisites

Ensure you have vagrant installed (should also support mac/windows)

https://www.vagrantup.com/docs/installation/

Also ensure you have virtualbox installed:

https://www.virtualbox.org/wiki/Downloads

## Run it

Clone this repo then:

```
vagrant up
```

## SSH into the VM
```
vagrant ssh
```

## Check minikube is up and running

```
kubectl get nodes
```

## Accessing ArgoCD UI

```
echo "ArgoCD password: $(kubectl -n argocd get pods --selector app.kubernetes.io/name=argocd-server --output name | cut -d'/' -f 2)"
echo "ArgoCD user: admin"
echo "ArgoCD url: $()"
```

## Access your code inside the VM

We automatically mount `/tmp/vagrant` into `/home/vagrant/data`.

For example, you may want to `git clone` some kubernetes manifests into `/tmp/vagrant` on your host-machine, then you can access them in the vagrant machine.

This is bi-directional, and achieved via [vagrant-sshfs](https://github.com/dustymabe/vagrant-sshfs)