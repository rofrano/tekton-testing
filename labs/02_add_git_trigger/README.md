# Tekton Triggers

Running a pipeline manually has limited uses. In this lab we will create a Tekton Trigger to cause a pipeline run from external events like changes made to a repo in GitHub.

## Setup

This lab starts with the `cd-pipeline` Pipeline and `checkout` and `echo` Tasks from the previous lab.

Apply them to your Kubernetes cluster before starting the lab:

```bash
kubectl apply -f tasks.yaml
kubectl apply -f pipeline.yaml
```

You will also need a ServiceAccount with the correct Role Based Access Control (RBAC) privileges which we have supplied in the `./rbac` folder. The setting up of a ServiceAccount and Role Base Access Control is beyond he scope of this lab, but these files are generic enough to use on your personal projects.

The ServiceAccount name to use for this lab is: `pipeline`.

Apply the RBAC rules now with:

```bash
kubectl apply -f rbac
```

## Step 1

### Create an EventListener

The first thing we need is an event listener that is listening for incoming events from GitHub.

Create the following `eventlistener.yaml` file that created an EventListener named `cd-listener` that references a TriggerBinding named `cd-binding` and a TriggerTemplate named `cd-template`:

```yaml
apiVersion: triggers.tekton.dev/v1alpha1
kind: EventListener
metadata:
  name: cd-listener
spec:
  serviceAccountName: pipeline
  triggers:
    - bindings:
      - ref: cd-binding
      template:
        ref: cd-template
```

Apply it to the cluster:

```bash
kubectl apply -f eventlistener.yaml
```

Check that it was created correctly.

```bash
$ tkn eventlistener ls

NAME          AGE             URL                                                    AVAILABLE
cd-listener   9 seconds ago   http://el-cd-listener.default.svc.cluster.local:8080   True
```

We will create the TriggerBinding named `cd-binding` and a TriggerTemplate named `cd-template` in the following steps:

## Step 2

We now let's create the TriggerBinding.

### Create a TriggerBinding

The next thing we need is a way to bind the incoming data from the event, to pass on to the pipeline. To accomplish this, we use a `TriggerBinding`

Create the following `triggerbinding.yaml` file that creates a TriggerBinding named `cd-binding` that takes the `body.repository.url` and `body.ref`, and binds them to the parameters `repository` and `branch` respectively.

```yaml
apiVersion: triggers.tekton.dev/v1alpha1
kind: TriggerBinding
metadata:
  name: cd-binding
spec:
  params:
    - name: repository
      value: $(body.repository.url)
    - name: branch
      value: $(body.ref)
```

Apply it to the cluster:

```bash
kubectl apply -f triggerbinding.yaml
```

## Step 3

We now let's create the TriggerTemplate.

### Create a TriggerTemplate

The TriggerTemplate takes the parameters passed in from the TriggerBinding and creates a PipelineRun to start the pipeline.

Create the following `triggertemplate.yaml` file that creates a TriggerTemplate named `cd-template` that defines the parameters required, and created a PipelineRun that will run the `cd-pipeline` that we created in the previous lab.

```yaml
apiVersion: triggers.tekton.dev/v1alpha1
kind: TriggerTemplate
metadata:
  name: cd-template
spec:
  params:
    - name: repository
      description: The git repo
      default: " "
    - name: branch
      description: the branch for the git repo
      default: master
  resourcetemplates:
    - apiVersion: tekton.dev/v1beta1
      kind: PipelineRun
      metadata:
        generateName: cd-pipeline-run-
      spec:
        serviceAccountName: pipeline
        pipelineRef:
          name: cd-pipeline
        params:
          - name: repo-url
            value: $(tt.params.repository)
          - name: branch
            value: $(tt.params.branch)
```

Note that while the parameter we bound from the event is `repository` we pass it on as `repo-url` to the pipeline. This is to show that the names do not ave to match allowing you to use any pipeline to map parameters into.

Apply it to the cluster:

```bash
kubectl apply -f triggertemplate.yaml
```

## Step 4

Now it's time to call the event listener and have it start a PipelineRun. We can do this locally using the `curl` command to test that it works.

Forward the port for the event listener so that can call it on `localhost`.

```bash
kubectl port-forward service/el-cd-listener  8090:8080
```

Use the `curl` command to send a payload to out event listener service.

```bash
curl -X POST http://localhost:8090 \
  -H 'Content-Type: application/json' \
  -d '{"repository":{"url":"https://github.com/rofrano/tekton-testing"}}'
```

This should start a PipelineRun. You can check on the status with this command:

```bash
$ $ tkn pipelinerun ls
NAME                    STARTED          DURATION   STATUS
cd-pipeline-run-hhkpm   10 seconds ago   ---        Running
```

You can also examine the PipelineRun logs using this command (the `-L` mean "latest" so that you don't have to look up the name for the last run):

```bash
tkn pipelinerun logs --last
```

You should see:

```bash
$ tkn pipelinerun logs --last
[clone : checkout] Cloning into 'tekton-testing'...

[lint : echo-message] Calling Flake8 linter...

[tests : echo-message] Running unit tests with PyUnit...

[build : echo-message] Building image for https://github.com/rofrano/tekton-testing ...

[deploy : echo-message] Deploying master branch of https://github.com/rofrano/tekton-testing ...
```

Congratulations, you've successfully set up Tekton Triggers.

## Complete

This completes the lab on creating a Tekton Triggers

Now that you know your triggers are working, you can expose the event listener service with an ingress and call it from a webhook in GitHub and have it run on changes to your GitHub repository.
