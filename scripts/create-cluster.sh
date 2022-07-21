#!/bin/bash
echo "************************************************************"
echo "Creating Kubernetes cluster with a registry..."
echo "************************************************************"
k3d cluster create --registry-create cluster-registry:0.0.0.0:32000 --port '8080:80@loadbalancer'
echo "************************************************************"
echo "Complete."
echo "************************************************************"

echo "************************************************************"
echo "Installing Tekton in the Cluster..."
echo "************************************************************"
kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
kubectl apply --filename https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml
kubectl apply --filename https://storage.googleapis.com/tekton-releases/triggers/latest/interceptors.yaml
kubectl apply --filename https://storage.googleapis.com/tekton-releases/dashboard/latest/tekton-dashboard-release.yaml
echo "************************************************************"
echo "Tekton install complete."
echo "************************************************************"
