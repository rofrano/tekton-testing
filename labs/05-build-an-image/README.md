# Build and Image

Welcome to the **Build an Image** lab. This is the next to last step in our CD pipeline. Before we can deploy our application, we need to build a Docker image. Luckily there are several tasks in the Tekton catalog that can do that. We will use one named `buildah`.

---

## Step 1

Our pipeline currently has a placeholder for a `build` step that uses the `echo` task. Now it's time to replace it with a real image builder.

### Add the buildah Task

We are going to use `buildah` to build our code. Luckily, Tekton Hub has a buildah task that we can install and use:

Install the buildah task using the Tekton CLI.

```bash
tkn hub install task buildah
```

This will install the `buildah` task in your Kubernetes namespace.

```
Task buildah(0.4) installed in default namespace
```

---

## Step 2

Now let's modify the `pipeline.yaml` file to use the new task.

### Modify the pipeline to use buildah

In reading the documentation for the **buildah** task you notice that it requires a workspace named `source`. Add the workspace to the `build` task after the name, but before the `taskref`:

```yaml
    - name: build
      workspaces:
        - name: source
          workspace: pipeline-workspace          
      taskRef:
```

We must now reference the new buildah task that we want to use. Change the `taskref` from `echo`, to reference the `buildah` task:

```yaml
      taskRef:
        name: buildah
```

The documentation for the buildah task details several parameters but only one of them is required. THat parameter is named `IMAGE`. This holds the name of the image you want to build.

Since you might want to reuse this pipeline to build different images, let's make it a parameter that can be passed in when the pipeline runs.

Change the `message` parameter to `IMAGE` and specify the value of `$(params.build-image)`:

```yaml
      params:
      - name: IMAGE
        value: "$(params.build-image)"
```

Now that we are passing in the image parameter to this task, we need to go back to the top of the `pipeline.yaml` file and add the parameter there so that it can be passed into the pipeline when it is run.

Add a parameter named `build-image` to the existing list of parameters.

```yaml
spec:
  params:
    - name: build-image
    - name: repo-url
    - name: branch
```

The full `build` task in the pipeline should look like this:

```yaml
    - name: build
      workspaces:
        - name: source
          workspace: pipeline-workspace          
      taskRef:
        name: buildah
      params:
      - name: IMAGE
        value: "$(params.build-image)"
      runAfter:
        - tests
```

Apply these changes to your cluster:

```bash
kubectl apply -f pipeline.yaml
```

### Run the pipeline

First make sure that the persistent volume claim for the workspace exists by applying it usinf `kubectl`:

```bash
kubectl apply -f pvc.yaml
```

When we start the pipeline, we now need to pass in the `build-image` parameter which is the name of the image to build.

This will be different for every learner that uses this lab. Here is the format:

```
image-registry.openshift-image-registry.svc:5000/sn-labs-<account>/tekton-lab:latest
```

Where `<account>` is your account name. If you don't know it, use the `hostname` command and your account name is the part to the right of the dash `-`.

For example, when I use `hostname` it shows me this:

```bash
$ hostname
theiaopenshift-rofrano
```

My account name is therefore `rofrano`. You should substitute yor account name in the image string above.

Then run the pipeline using the Tekton CLI to see our new build task run:

```bash
tkn pipeline start cd-pipeline \
    -p repo-url="https://github.com/rofrano/tekton-testing.git" \
    -p build-image=image-registry.openshift-image-registry.svc:5000/sn-labs-rofrano/tekton-lab:latest \
    -w name=pipeline-workspace,claimName=pipelinerun-pvc \
    --showlog
```

You should see the pipeline run complete successfully.

You can see the pipeline run status by listing the PipelineRuns with:

```bash
tkn pipelinerun ls
```

You should see:

```bash
$ tkn pipelinerun ls
NAME                    STARTED         DURATION     STATUS
cd-pipeline-run-fbxbx   1 minute ago    59 seconds   Succeeded
```

You can check the logs of the last run with:

```bash
tkn pipelinerun logs --last
```

## Complete

Congratulations! You have just added the ability to build a docker image and push it to teh registry in OpenShift.
