# Tekton Testing

This repo is for experimenting with Tekton pipelines

## Software Installs

Install Tekton in your Kubernetes cluster:

```bash
kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
kubectl apply --filename https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml
kubectl apply --filename https://storage.googleapis.com/tekton-releases/triggers/latest/interceptors.yaml
kubectl apply --filename https://storage.googleapis.com/tekton-releases/dashboard/latest/tekton-dashboard-release.yaml
```

## Install the Tekton CLI

Mac

```bash
brew install tektoncd-cli
```

Linux

```bash
sudo apt update;sudo apt install -y gnupg
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3EFE0E0A2F2F60AA
echo "deb http://ppa.launchpad.net/tektoncd/cli/ubuntu eoan main"|sudo tee /etc/apt/sources.list.d/tektoncd-ubuntu-cli.list
sudo apt update && sudo apt install -y tektoncd-cli
```

## Tekton Hub

You can find tasks at [hub.tekton.dev](http://hub.tekton.dev)

You can install tasks using the Tekton CLI (`tkn`)

```bash
tkn hub install task git-clone
```

## Run a Pipeline

You can run a pipeline using the Tekton CLI:

```bash
tkn pipeline start --showlogs .tekton/pipeline.yaml
```

### Optional

If working in the terminal in becomes difficult because the command prompt is very long, you can shorten the prompt using the following command:

```bash
export PS1="[\[\033[01;32m\]\u@\h\[\033[00m\]: \[\033[01;34m\]\W\[\033[00m\]]\$ "
```
