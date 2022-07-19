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
      args: ["$(params.message)"]
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

You should see the output:

```bash
PipelineRun started: message-pipeline-run-r48dk
Waiting for logs to be available...
[talk : echo-message] Tekton ROCKS!
```

## Step 3

In this step we will take our knowledge of running a command in a container with our knowledge of passing parameters and make a task that checks out our code from GitHub.

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

### Create the cd-pipeline pipeline

Finally we will create a Pipeline called `cd-pipeline` to be the starting point of our Continuous Integration pipeline.

```yaml
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:  
  name: cd-pipeline
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

### Run the cd-pipeline

Run the pipeline using the Tekton CLI:

```bash
tkn pipeline start cd-pipeline \
    --showlog \
    -p repo-url="https://github.com/rofrano/tekton-testing.git" \
    -p branch="master"
```

The output should look like this:

```bash
PipelineRun started: cd-pipeline-run-2ps4l
Waiting for logs to be available...
[clone : checkout] Cloning into 'tekton-testing'...
```

## Step 4

In this final step we will fill out the rest of the pipeline with calls to the `echo` task to simple echo a message for now. We will replace these "placeholder" tasks with real ones in future labs.

### Fill out the cd-pipeline with placeholders

Now we will add four tasks to the pipeline to `lint`, `unit-test`, `build`, and `deploy`. All of these pipeline tasks will reference the `echo` task for now.

Update the `pipeline.yaml` file to include these placeholder tasks.

```yaml
    - name: lint
      taskRef:
        name: echo
      params:
      - name: message
        value: "Calling Flake8 linter..."
      runAfter:
        - clone

    - name: tests
      taskRef:
        name: echo
      params:
      - name: message
        value: "Running unit tests with PyUnit..."
      runAfter:
        - lint

    - name: build
      taskRef:
        name: echo
      params:
      - name: message
        value: "Building image for $(params.repo-url) ..."
      runAfter:
        - tests

    - name: deploy
      taskRef:
        name: echo
      params:
      - name: message
        value: "Deploying $(params.branch) branch of $(params.repo-url) ..."
      runAfter:
        - build
```

You now have a base pipeline to build the rest of your tasks into.

Apply it to the cluster:

```bash
kubectl apply -f pipeline.yaml
```

### Run the cd-pipeline

Run the pipeline using the Tekton CLI:

```bash
tkn pipeline start cd-pipeline \
    --showlog \
    -p repo-url="https://github.com/rofrano/tekton-testing.git" \
    -p branch="master"
```

The output should look like this:

```bash
PipelineRun started: cd-pipeline-run-2ps4l
Waiting for logs to be available...
[clone : checkout] Cloning into 'tekton-testing'...
```

Out should see output like this:

```bash
Pipelinerun started: cd-pipeline-run-k6925
Waiting for logs to be available...
[clone : checkout] Cloning into 'tekton-testing'...

[lint : echo-message] Calling Flake8 linter...

[tests : echo-message] Running unit tests with PyUnit...

[build : echo-message] Building image for https://github.com/rofrano/tekton-testing.git ...

[deploy : echo-message] Deploying master branch of https://github.com/rofrano/tekton-testing.git ...
```

## Complete

This completes the lab on creating a basic pipeline
