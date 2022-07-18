# Using the Tekton Catalog

The Tekton community provides a wide selection of Tasks that you can use in your pipelines so that you don't have to write all of them yourself. Many common tasks can be found at the [Tekton Hub](http://hub.tekton.dev). This lab will use one of them.

## Step 1

### Add the git-clone task

We will start by finding a task to replace the `checkout` task that we initially created ourselves. While it was OK as a learning exercise, there are a lot more capabilities that it needs to be more robust, and it makes sense to use the community supplied task instead.

(Optional) You can browse the Tekton Hub and find the [git-clone](https://hub.tekton.dev/tekton/task/git-clone) command and copy the URL to the `yaml` file and use `kubectl` to apply it manually, but it's must easier to use the Tekton CLI once you have found the task that you want.

Use this command to install the `git-clone- task from tekton Hub:

```bash
tkn hub install task git-clone
```

This will install the `git-clone` task into your cluster under your current active namespace.

## Step 2

In looking at the requirements to use the `git-clone` task we see that, while it supports many more parameters than our original `checkout` task, it only _requires_ 2 things:

1. The URL of a git repo to clone provided with the `url` param
1. A Workspace called `output`

Let's start by creating a `PersistentVolumeClaim` to use as the workspace:

### Create a workspace

A workspace is a disk volume that can be shared across tasks. The way to bind to volumes in Kubernetes is with a `PersistentVolumeClaim` (PVC).

Since creating PersistentVolumeClaims is beynd the scope of this lab, we have provided you with the following `pvc.yaml` file with the following contents:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pipelinerun-pvc
spec:
  resources:
    requests:
      storage:  1Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
```

Apply it to your cluster:

```bash
kubectl apply -f pvc.yaml
```

We can now reference this persistent volume by it's name `pipelinerun-pvc` when creating workspaces for our Tekton tasks.

## Step 3

In this step will will add a workspace to the pipeline using the persistent volume claim we just created.

### Add workspace to the pipeline

Let's define a workspace for the `cd-pipeline` pipeline.

Edit the `pipeline.yaml` file and add a `workspaces` definition as the first line under the `spec` but before the `params` and call it `pipeline-workspace`.

```yaml
spec:
  workspaces:
    - name: pipeline-workspace
  params:
  ...
```

Also add the workspace to the `clone` task after the `name` and call it `output` because this is the workspace name that the `git-clone` task will be looking for.

```yaml
    - name: clone
      workspaces:
        - name: output
          workspace: pipeline-workspace          
      taskRef:
```

Change the name of the `taskRef` in the `clone` task to reference the `git-clone` task instead of `checkout`.

```yaml
      taskRef:
        name: git-clone
```

Finally change the name of the `repo-url` parameter to be `url` because this is what the `git-clone` tasks expects the parameter to be named, but keep the mapping of `$(params.repo-url)` which is what the pipeline expects.

```yaml
      - name: url
        value: $(params.repo-url)
```

The complete `clone` task in your pipeline should look like this:

```yaml
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:  
  name: cd-pipeline
spec:
  workspaces:
    - name: pipeline-workspace
  params:
    - name: repo-url
    - name: branch
      default: "master"
  tasks:
    - name: clone
      workspaces:
        - name: output
          workspace: pipeline-workspace          
      taskRef:
        name: git-clone
      params:
      - name: url
        value: $(params.repo-url)
      - name: revision
        value: $(params.branch)

    # Note: The remaining Tasks are unchanged
```

Apply the pipeline and previous tasks to your cluster:

```bash
kubectl apply -f tasks.yaml
kubectl apply -f pipeline.yaml
```

You are now ready to run your pipeline.

## Step 4

### Run the pipeline

We can now use the Tekton CLI (`tkn`) to create a PipelineRun that will run the pipeline.

```bash
tkn pipeline start cd-pipeline \
    -p repo-url="https://github.com/rofrano/tekton-testing.git" \
    -w name=pipeline-workspace,claimName=pipelinerun-pvc \
    --showlog
```

You can see the pipeline run status by listing the PipelineRuns with:

```bash
tkn pipelinerun ls
```

You should see:

```bash
$ tkn pipelinerun ls
NAME                    STARTED          DURATION     STATUS
cd-pipeline-run-mrg6g   45 seconds ago   18 seconds   Succeeded
```

You can check the logs of the last run with:

```bash
tkn pipelinerun logs --last
```

## Complete

Congratulations! You have just used a task from the Tekton catalog instead of writing it yourself. We will use a combination of self written and catalog tasks to fill put our pipeline in future labs.
