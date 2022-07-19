# Integrating Unit Test Automation

Welcome to Integrating Unit Test Automation. In this lab we will take the code that was cloned in the previous pipeline step and run linting and unit tests against it to make sure it is ready to be built and deployed.

---

## Step 1

Our pipeline has a placeholder for a `lint` step that uses the `echo` task. Now it's time to replace it with a real linter.

### Add the flake8 Task

We are going to use `flake8` to lint our code. Luckily, Tekton Hub has a flake8 task that we can install and use:

Install the flake8 task using the Tekton CLI.

```bash
tkn hub install task flake8
```

This will install the `flake8` task in your Kubernetes namespace.

---

## Step 2

Now let's modify the `pipeline.yaml` file to use the new task.

### Modify the pipeline to use flake8

In reading the documentation for the **flake8** task you notice that it requires a workspace named `source`. Add the workspace to the `lint` task after the name, but before the `taskref`:

```yaml
    - name: lint
      workspaces:
        - name: source
          workspace: pipeline-workspace          
      taskRef:
```

Change the `taskref` from `echo`, to reference the `flake8` task:

```yaml
      taskRef:
        name: flake8
```

The documentation for the flake8 task also allows you to pass in arguments through an `args` parameter and you can use your own Docker image using the `image` parameter. Let's use the `python:3.9-slim` image and add our favorite options as args.

Change the `message` parameter to the `image` parameter to specify the value of `python:3.9-slim`:

```yaml
      params:
      - name: image
        value: "python:3.9-slim"
```

Add a new parameter called `args` to specify the arguments "--count --max-complexity=10 --max-line-length=127 --statistics" to pass to the flake8. The documentation tells us that this must be passed as an array:

```yaml
      - name: args
        value: ["--count","--max-complexity=10","--max-line-length=127","--statistics"]
```

The full `lint` task in the pipeline should look like this:

```yaml
    - name: lint
      workspaces:
        - name: source
          workspace: pipeline-workspace          
      taskRef:
        name: flake8
      params:
      - name: image
        value: "python:3.9-slim"
      - name: args
        value: ["--count","--max-complexity=10","--max-line-length=127","--statistics"]
      runAfter:
        - clone
```

Apply these changes to your cluster:

```bash
kubectl apply -f pipeline.yaml
```

### Run the pipeline

First create the persistent volume claim for the workspace:

```bash
kubectl apply -f pvc.yaml
```

Then run the pipeline using the Tekton CLI to see our new lint task run:

```bash
tkn pipeline start cd-pipeline \
    -p repo-url="https://github.com/rofrano/tekton-testing.git" \
    -w name=pipeline-workspace,claimName=pipelinerun-pvc \
    --showlog
```

You should see the pipeline run complete successfully.

---

## Step 3

Our pipeline also has a placefolder for a `tests` task that uses the `echo` Task. Now it's time to replace it with real unit tests. In this step we will replace the `echo` task with a call to a unittest framework called `nosetests`.

### Create a test Task

There are no tasks in the Tekton Hub for `nosetests` so we will write our own.

Update the `tasks.yaml` file with a new Task called `nose` that uses the shared workspace for the pipeline and runs `nosetests` in a `python:3.9-slim` image as a shell script.

You will need to use `pip` to install the Python dependencies for the application. This also installs `nose`.

Here is a bash script to install the Python requirements and run the nose tests:

```bash
#!/bin/bash
set -e
python -m pip install --upgrade pip wheel
pip install -r requirements.txt
nosetests -v --with-spec --spec-color
```

We will use this script in the Task. Let's start by defining a Task called `nose`:

```yaml
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: nose
```

It might be a good idea to allow the passing in of different arguments to nosetests so create a parameter called `args` just like the `flake8` task has, and give it the verbose flag "-v" as the default:

```yaml
spec:
  params:
    - name: args
      description: Arguments to pass to nose
      type: string
      default: "-v"
```

Next we need to include the workspace that has the code that we want to test. Since flake8 uses the name `source`, let's use that for consistency.

```yaml
  workspaces:
    - name: source
```

Finally, we specify the steps, of which there is only one. Give it the name `nosetests` and have it run in a `python:3.9-slim` image. Also specify the `workingDir` as the path to the workspace we defined (i.e., `$(workspaces.source.path)`). Then paste the script from above in the `script` parameter.

```yaml
  steps:
    - name: nosetests
      image: python:3.9-slim
      workingDir: $(workspaces.source.path)
      script: |
        #!/bin/bash
        set -e
        python -m pip install --upgrade pip wheel
        pip install -r requirements.txt
        nosetests $(params.options)
```

The finished task should look like this:

```yaml
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: nose
spec:
  params:
    - name: args
      description: Arguments to pass to nose
      type: string
      default: "-v"
  workspaces:
    - name: source
  steps:
    - name: nosetests
      image: python:3.9-slim
      workingDir: $(workspaces.source.path)
      script: |
        #!/bin/bash
        set -e
        python -m pip install --upgrade pip wheel
        pip install -r requirements.txt
        nosetests $(params.options)
```

Apply these changes to your cluster:

```bash
kubectl apply -f tasks.yaml
```

---

## Step 4

Modify the `pipeline.yaml` file to use the new `nose` task.

### Modify the pipeline to use nose

Edit the `pipeline.yaml` file. Add the workspace to the `tests` task after the name but before the `taskref`:

```yaml
    - name: tests
      workspaces:
        - name: source
          workspace: pipeline-workspace          
      taskRef:
```

Change the `taskref` from `echo` to reference our new `nose` tas:

```yaml
      taskRef:
        name: nose
```

Change the `message` parameter to the `args` parameter to specify the arguments to pass to the tests:

```yaml
      params:
      - name: args
        value: "-v --with-spec --spec-color"
```

The full `tests` task should look like this:

```yaml
    - name: tests
      workspaces:
        - name: source
          workspace: pipeline-workspace          
      taskRef:
        name: nose
      params:
      - name: args
        value: "-v --with-spec --spec-color"
      runAfter:
        - lint
```

Apply these changes to your cluster:

```bash
kubectl apply -f pipeline.yaml
```

### Run the pipeline again

Let's run the pipeline using the Tekton CLI to see our new lint task run:

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
NAME                    STARTED         DURATION     STATUS
cd-pipeline-run-fbxbx   1 minute ago    59 seconds   Succeeded
```

You can check the logs of the last run with:

```bash
tkn pipelinerun logs --last
```

## Complete

Congratulations! You have just created your own tasks to lint your code and run unittests.
