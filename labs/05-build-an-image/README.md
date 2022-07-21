# Building and Image

Welcome to the hands-on lab for **Building an Image**. You are now at the build step, which is the next to last step in your CD pipeline. Before you can deploy your application, you need to build a Docker image. Luckily, there are several tasks in the Tekton catalog that can do that. You will use one named `buildah`.

## Learning Objectives

After completing this lab, you will be able to:

- Install the buildah task from the Tekton CD Catalog
- Describe the parameters required to use the buildah task
- Use the buildah task in a Tekton pipeline to build an image and push it to an image registry

---

### Prerequisites

If you did not compete the previous labs you will need to run the following commands to catchup and get yor environment ready for this lab. If you have completed the previous labs you may skip this step although repeating it will not harm anything.

Issue the following commands to install everything you would have in the previous steps.

```bash
tkn hub install task git-clone
tkn hub install task flake8
kubectl apply -f tasks.yaml
```

Check that you have all of the previous tasks installed:

```bash
tkn task ls
```

You should see:

```txt
NAME               DESCRIPTION              AGE
git-clone          These Tasks are Git...   2 minutes ago
flake8             This task will run ...   1 minute ago
echo                                        46 seconds ago
nose                                        46 seconds ago
```

You are now ready to continue with this lab.

---

## Step 1: Install the buildah task

Our pipeline currently has a placeholder for a `build` step that uses the `echo` task. Now it's time to replace it with a real image builder.

We are going to use `buildah` to build our code. Luckily, Tekton Hub has a buildah task that we can install and use:

Install the buildah task using the Tekton CLI.

```bash
tkn hub install task buildah
```

This will install the `buildah` task in your Kubernetes namespace. You see a reply like this one to indicate that the buildah task was installed successfully.

```
Task buildah(0.4) installed in default namespace
```

---

## Step 2: Add a workspace to the pipeline

Now let's update the `pipeline.yaml` file to use the new `buildah` task.

Open `pipeline.yaml` in the editor. To open the editor, click the button below.

---

In reading the documentation for the **buildah** task you notice that it requires a workspace named `source`. 

Add the workspace to the `build` task after the name, but before the `taskref`. The workspace that we have been using is named `pipeline-workspace` and name the task requires is named `source`.

```yaml
    - name: build
      workspaces:
        - name: source
          workspace: pipeline-workspace          
      taskRef:
```

---

## Step 3: Reference the buildah task

We must now reference the new buildah task that we want to use. Change the `taskref` from `echo`, to reference the `buildah` task:

```yaml
      taskRef:
        name: buildah
```

---

## Step 4: Update the task parameters

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

---

## Step 5: Apply changes to the cluster

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

---

## Step 6: Run the pipeline

First, make sure that the persistent volume claim for the workspace exists by applying it using `kubectl`:

```bash
kubectl apply -f pvc.yaml
```

When we start the pipeline, we now need to pass in the `build-image` parameter which is the name of the image to build.

This will be different for every learner that uses this lab. Here is the format:

```
image-registry.openshift-image-registry.svc:5000/$SN_ICR_NAMESPACE/tekton-lab:latest
```

Notice the variable `$SN_ICR_NAMESPACE` in the image name. This is set automatically to point to your container namespace.

Then run the pipeline using the Tekton CLI to see our new build task run:

```bash
tkn pipeline start cd-pipeline \
    -p repo-url="https://github.com/ibm-developer-skills-network/wtecc-CICD_PracticeCode.git" \
    -p build-image=image-registry.openshift-image-registry.svc:5000/$SN_ICR_NAMESPACE/tekton-lab:latest \
    -w name=pipeline-workspace,claimName=pipelinerun-pvc \
    --showlog
```

You should see the pipeline run complete successfully.

You can see the pipeline run status by listing the PipelineRuns with:

```bash
tkn pipelinerun ls
```

You should see:

```txt
NAME                    STARTED         DURATION     STATUS
cd-pipeline-run-fbxbx   1 minute ago    59 seconds   Succeeded
```

You can check the logs of the last run with:

```bash
tkn pipelinerun logs --last
```
---

## Complete

Congratulations! You have just added the ability to build a docker image and push it to teh registry in OpenShift.
