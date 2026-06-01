## Career Objective

Aspiring DevOps Engineer with a strong interest in cloud-native technologies, Kubernetes, AWS, CI/CD automation, observability, and infrastructure automation. Seeking opportunities to build scalable, secure, and reliable platforms while continuously improving software delivery and operational excellence.

## Architectural decisions

- Jenkins for pipeline
- Dockerhub for storing images
- Dockerhub credentials are setup in jenkins
- Docker commons and AWS plugins are installed in jenkins
- Using helm for the EKS cluster

## Assumptions

- A package*.json file existing to build a docker img from
- Existing EKS cluster
- NGINX Ingress Controller installed
- Prometheus Operator installed
- Docker Hub repository available
- Docker Hub repository secrets configured
- Application exposes:
  - /health
  - /metrics

## Setup istructions

### Deploy
helm upgrade --install node-api helm/node-api
### Verify
kubectl get pods
kubectl get svc
kubectl get ingress
kubectl get hpa