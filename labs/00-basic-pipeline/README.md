# Tekton Pipelines

In this lab we will create a simple Tekton pipelines with one task in **Step 1** and then add a parameter to it in **Step 2**.

## Step 1

### Create an echo Task

It true computer programming tradition, the first task will echo "Hello World!" to the console.

Create the following `tasks.yaml` file:

```yaml
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: hello-world
spec:
  steps:
    - name: echo
      image: alpine:3
      command: [/bin/echo]
      args: ["Hello World!"]
```

Apply it to the cluster:

```bash
kubectl apply -f tasks.yaml
```

### Create a hello-pipeline

Next we will create the simplest of pipelines that only calls the `echo` task that we just created.

Create the following `pipeline.yaml` file that uses the task:

```yaml
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:  
  name: hello-pipeline
spec:
  tasks:
    - name: say-hello
      taskRef:
        name: hello-world
```

Apply it to the cluster:

```bash
kubectl apply -f pipeline.yaml
```

### Run the hello-pipeline

Run the pipeline using the Tekton CLI:

```bash
tkn pipeline start --showlog hello-pipeline
```

You should see the output:

```bash
PipelineRun started: hello-pipeline-run-9vkbb
Waiting for logs to be available...
[say-hello : echo] Hello World!
```

## Step 2

In this step we will add a parameter to the task that will be passed in from the pipeline.

### Add a parameter to the Task

Next we will add a parameter called `message`to the task and use that parameter as the message that we echo. Let's call this new task `echo`.

Edit the `tasks.yaml` file to add the parameter to both the input and the echo command:

```yaml
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: echo
spec:
  params:
    - name: message
      description: The message to echo
      type: string
  steps:
    - name: echo-message
      image: alpine:3
      command: [echo]
      args: ["$(params.message"]
```

Apply the new task definition to the cluster:

```bash
kubectl apply -f tasks.yaml
```

### Create a message pipeline

This pipeline will pass the message that you send it as a parameter on to the task that will echo the message to the console.

Edit the `pipeline.yaml` file to add the parameter:

```yaml
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:  
  name: message-pipeline
spec:
  params:
    - name: message
  tasks:
    - name: talk
      taskRef:
        name: echo
      params:
        - name: message
          value: "$(params.message)"
```

Apply it to the cluster:

```bash
kubectl apply -f pipeline.yaml
```

### Run the message-pipeline

Run the pipeline using the Tekton CLI:

```bash
tkn pipeline start message-pipeline \
    --showlog  \
    -p message="Tekton ROCKS!"
```

## Step 3

In this step we will take our knowledge of running a command in a container with our knowledge of passing parameters and make a task that checksour code from GitHub.

### Create checkout task

Create a new task that uses the `bitnami/git:latest` image to run the `git` command passing in the branch name and URL of the repo you want to clone.

```yaml
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: checkout
spec:
  params:
    - name: repo-url
      description: The URL of the git repo to clone
      type: string
    - name: branch
      description: The branch to clone
      type: string
  steps:
    - name: checkout
      image: bitnami/git:latest
      command: [git]
      args: ["clone", "--branch", "$(params.branch)", "$(params.repo-url)"]
```

Apply it to the cluster:

```bash
kubectl apply -f tasks.yaml
```

### Create the ci-pipeline pipeline

Finally we will create a Pipeline called `ci-pipeline` to be the starting point of our Continuous Integration pipeline.

```yaml
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:  
  name: ci-pipeline
spec:
  params:
    - name: repo-url
    - name: branch
      default: "master"
  tasks:
    - name: clone
      taskRef:
        name: checkout
      params:
      - name: repo-url
        value: "$(params.repo-url)"
      - name: branch
        value: "$(params.branch)"
```

Apply it to the cluster:

```bash
kubectl apply -f pipeline.yaml
```

### Run the ci-pipeline

Run the pipeline using the Tekton CLI:

```bash
tkn pipeline start ci-pipeline \
    --showlog \
    -p repo-url="https://github.com/rofrano/tekton-testing.git" \
    -p branch="master"
```

The output should look like this:

```bash
PipelineRun started: ci-pipeline-run-2ps4l
Waiting for logs to be available...
[clone : checkout] Cloning into 'tekton-testing'...
```

This completes the lab on creating a basic pipeline
