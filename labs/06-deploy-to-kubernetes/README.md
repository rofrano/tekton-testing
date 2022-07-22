# Deploy to Kubernetes

Welcome to the hands-on lab for **Deploy to Kubernetes**. We are now at the deploy step which is the last step in our CD pipeline. For this step we will use the OpenShift client to deploy our Docker image to Kubernetes.

## Learning Objectives

After completing this lab, you will be able to:

- Determine if the openshift-client ClusterTask is available on your cluster
- Describe the parameters required to use the openshift-client ClusterTask
- Use the openshift-client task in a Tekton pipeline to deploy your Docker image to Kubernetes

---

## Prerequisites

If you did not compete the previous labs you will need to run the following commands to catchup and get yor environment ready for this lab.

```bash
tkn hub install task git-clone
tkn hub install task flake8
kubectl apply -f tasks.yaml
kubectl apply -f pvc.yaml
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

## Step 1: Check for the openshift-client ClusterTask

Your pipeline currently has a placeholder for a `deploy` step that uses the `echo` task. Now it's time to replace it with a real deployment.

Knowing that you want to deploy to OpenShift, you search Tekton Hub for the word "openshift" and you see there is a task called `openshift-client` that will execute OpenShift commands on your cluster. This will be perfect for deploying our image so you decide to use the `openshift-client` task in your pipeline to deploy your image.

Instead of installing it yourself, you first check the ClusterTasks in your cluster to see if it already exists. Luckily, the OpenShift environment you are using already has `openshift-client` installed as a **ClusterTask**. A ClusterTask is installed cluster-wide by an administrator and anyone can use it in their pipelines without having to install it themselves.

Check that the `openshift-client` task is installed as a ClusterTask using the Tekton CLI.

```bash
tkn clustertask ls
```

You should see the `openshift-client` task in the list with all the other available ClusterTasks.

```
NAME               DESCRIPTION              AGE
openshift-client   This task runs comm...   32 weeks ago
...
```

If you see it, you are ready to proceed.

---

## Step 2: Reference the openshift-client task

Open the `pipeline.yaml` file and scroll down to the `deploy` task.

We must now reference the new openshift-client ClusterTask that we want to use in the `deploy` pipeline task.

Now, you need to reference the new openshift-client ClusterTask that you want to use. In the previous steps, you simply changed the name of the reference to the task. But since the `openshift-client` task is installed as a **ClusterTask**, you need to add the statement `kind: ClusterTask` under the name so that Tekton knows to look for a **ClusterTask** and not a regular **Task**.

Change the `taskRef` from `echo` to  `openshift-client` and add a line below it with `kind: ClusterTask` to indicate that this is a ClusterTask:

```yaml
      taskRef:
        name: openshift-client
        kind: ClusterTask
```

---

## Step 3: Update the task parameters

The documentation for the `openshift-client` task details there is a parameter named `SCRIPT`that you can use to execute `oc` commands. Any command you can use with `kubectl` can also be used with `oc`. This is what you will use to deploy your image.

The command to deploy an image on OpenShift is:

```bash
oc create deployment {name} --image={image-name}
```

Since you might want to reuse this pipeline to deploy different applications, let's make the deployment name a parameter that can be passed in when the pipeline runs. We already have the image name as a parameter from the build task.

Change the `message` parameter to `SCRIPT` and specify the value of `"oc create deploy $(params.app-name) --image=$(params.build-image)"` in quotes.

```yaml
      params:
      - name: SCRIPT
        value: "oc create deploy $(params.app-name) --image=$(params.build-image)"
```

## Step 4: Update the pipeline parameters

Now that we are passing in the `app-name` parameter to the `deploy` task, we need to go back to the top of the `pipeline.yaml` file and add the parameter there so that it can be passed into the pipeline when it is run.

### Your Task

Add a parameter named `app-name` to the existing list of parameters at the top of the pipeline under `spec.params`.

```yaml
spec:
  params:
    - name: app-name
```

---

## Step 5: Apply changes to the cluster

The full `deploy` task in the pipeline should look like this:

```yaml
    - name: deploy
      taskRef:
        name: openshift-client
        kind: ClusterTask
      params:
      - name: SCRIPT
        value: "oc create deploy $(params.app-name) --image=$(params.build-image)"
      runAfter:
        - build
```

Apply these changes to your cluster:

```bash
kubectl apply -f pipeline.yaml
```

---

## Step 6: Run the pipeline

In this final step we will apply the pipeline to our cluster and run it.

### Apply the pipeline

Apply the same changes you just made to `pipeline.yaml` to your cluster:

```bash
kubectl apply -f pipeline.yaml
```

### Start the pipeline

When you start the pipeline, you now need to pass in the `app-name` parameter, which is the name of the application to deploy.

Our application is called `hitcounter` so this is the name that we will pass in, in addition to all of the other parameters from the previous steps.

Now, start the pipeline to see your new deploy task run. Use the Tekton CLI `pipeline start` command to run the pipeline, passing in the parameters `repo-url`, `branch`, `app-name`, and `build-image` using the `-p` option. Specify the workspace `pipeline-workspace` and volume claim `pipelinerun-pvc` using the `-w` option:

```bash
tkn pipeline start cd-pipeline \
    -p repo-url="https://github.com/ibm-developer-skills-network/wtecc-CICD_PracticeCode.git" \
    -p branch=main \
    -p app-name=hitcounter \
    -p build-image=image-registry.openshift-image-registry.svc:5000/$SN_ICR_NAMESPACE/tekton-lab:latest \
    -w name=pipeline-workspace,claimName=pipelinerun-pvc \
    --showlog
```

You should see `Waiting for logs to be available...` while the pipeline runs. The logs will be shown on the screen. Wait until the pipeline run completes successfully.

### Getting status

You can see the pipeline run status by listing the pipeline runs with:

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
