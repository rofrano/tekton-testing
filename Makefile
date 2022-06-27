.PHONY: all help venv install lint test build push deploy redeploy

help: ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-\\.]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

all: help

venv: ## Create a Python virtual environment
	$(info Creating Python 3 virtual environment...)
	python3 -m venv .venv

install: ## Install dependencies
	$(info Installing dependencies...)
	sudo pip install -r requirements.txt

lint: ## Run the linter
	$(info Running linting...)
	flake8 service --count --select=E9,F63,F7,F82 --show-source --statistics
	flake8 service --count --max-complexity=10 --max-line-length=127 --statistics

test: ## Run the unit tests
	$(info Running tests...)
	nosetests --with-spec --spec-color

build: ## Build a Docker image
	$(info Building Docker image...)
	docker build --rm -t hitcounter:1.0 . 

push: ## Push image to registry
	$(info Building Docker image...)
	docker tag hitcounter:1.0 localhost:32000/hitcounter:1.0
	docker push localhost:32000/hitcounter:1.0

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
