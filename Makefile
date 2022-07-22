.PHONY: all
all: help

.PHONY: help
help: ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-\\.]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: cluster
cluster: ## Create a Kubernetes cluster
	$(info Creating Kubernetes cluster with a registry...)
	k3d cluster create --registry-create cluster-registry:0.0.0.0:32000 --port '8080:80@loadbalancer'

tekton: ## Install Tekton
	$(info Installing Tekton in the Cluster...)
	kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
	kubectl apply --filename https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml
	kubectl apply --filename https://storage.googleapis.com/tekton-releases/triggers/latest/interceptors.yaml
	kubectl apply --filename https://storage.googleapis.com/tekton-releases/dashboard/latest/tekton-dashboard-release.yaml

.PHONY: venv
venv: ## Create a Python virtual environment
	$(info Creating Python 3 virtual environment...)
	python3 -m venv .venv

.PHONY: install
install: ## Install Python dependencies
	$(info Installing Python dependencies...)
	sudo pip install -r requirements.txt

.PHONY: lint
lint: ## Run the linter
	$(info Running linting...)
	flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics
	flake8 . --count --max-complexity=10 --max-line-length=127 --statistics

.PHONY: test
test: ## Run the unit tests
	$(info Running tests...)
	nosetests --with-spec --spec-color

.PHONY: build
build: ## Build a Docker image
	$(info Building Docker image...)
	docker build --rm -t hitcounter:1.0 . 

.PHONY: push
push: ## Push image to registry
	$(info Building Docker image...)
	docker tag hitcounter:1.0 localhost:32000/hitcounter:1.0
	docker push localhost:32000/hitcounter:1.0

tasks: ## Create Tekton Cluster Tasks
	$(info Creating Tekton Cluster Tasks...)
	wget -qO - https://raw.githubusercontent.com/tektoncd/catalog/main/task/openshift-client/0.2/openshift-client.yaml | sed 's/kind: Task/kind: ClusterTask/g' | kubectl create -f -
	wget -qO - https://raw.githubusercontent.com/tektoncd/catalog/main/task/buildah/0.4/buildah.yaml | sed 's/kind: Task/kind: ClusterTask/g' | kubectl create -f -

# deploy: ## Deploy to Kubernetes
# 	$(info Deploying to Kubernetes...)
# 	kubectl apply -f deploy/redis.yaml
# 	kubectl apply -f deploy/secrets.yaml
# 	kubectl apply -f deploy/deployment.yaml
# 	kubectl apply -f deploy/service.yaml
# 	kubectl apply -f deploy/ingress.yaml

# redeploy: ## Force a redeploy of deployment
# 	$(info Redeploying to Kubernetes...)
# 	kubectl delete --ignore-not-found=true -f deploy/deployment.yaml
# 	kubectl create -f deploy/deployment.yaml
