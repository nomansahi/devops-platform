\# DevOps Platform Lab



A local Kubernetes project using Terraform and GitHub Actions.



\## Current implementation



\- Instrumented Python application with HTTP and SQLite endpoints.

\- Minikube Kubernetes cluster.

\- Terraform-managed namespace, Deployment, and Service.

\- Two application replicas.

\- Readiness and liveness probes.

\- CPU and memory requests and limits.

\- Automated Terraform validation and container build.

\- Three application behavior tests.

\- Evidence of pod replacement and scaling.



Terraform manages resources inside an existing cluster.

It does not provision the Minikube cluster.



\## Requirements



\- Docker Desktop with Linux containers.

\- Minikube.

\- Terraform 1.12 or newer, below 2.0.

\- PowerShell.



Tested locally with Minikube 1.38.1, Kubernetes 1.35.1,

and Terraform 1.12.2.



Use minikube kubectl -- to run a client matching the cluster.



\## Start the cluster



```powershell

minikube start

minikube kubectl -- get nodes

```



\## Build the application image



From the project root:



```powershell

minikube image build -t practice-app:v1 ./app

```



The local deployment uses this image inside Minikube.



\## Deploy with Terraform



```powershell

Copy-Item .\\terraform\\lab.example.tfvars .\\terraform\\lab.tfvars

terraform -chdir=terraform init

terraform -chdir=terraform validate

terraform -chdir=terraform plan "-var-file=lab.tfvars" "-out=deploy.tfplan"

terraform -chdir=terraform apply "deploy.tfplan"

```



For a fresh setup, Terraform creates the namespace, Deployment,

and Service.



If devops-lab resources already exist but are absent from Terraform

state, import them first:



```powershell

terraform -chdir=terraform import kubernetes\_namespace\_v1.lab devops-lab

terraform -chdir=terraform import kubernetes\_deployment\_v1.app devops-lab/practice-app

terraform -chdir=terraform import kubernetes\_service\_v1.app devops-lab/practice-app

```



Review the plan after importing before applying any differences.



Terraform is the source of truth for these resources.

k8s/app.yml is the initial bootstrap reference, with one replica.

Do not reapply it over the Terraform-managed deployment.



\## Verify and access



```powershell

minikube kubectl -- rollout status deployment/practice-app -n devops-lab --timeout=120s

minikube kubectl -- get pods -n devops-lab

minikube kubectl -- port-forward -n devops-lab service/practice-app 8080:80

```



Keep port-forwarding running.

Open http://localhost:8080 in the browser.



Port-forwarding selects a pod; it does not demonstrate balancing

requests across both replicas. Restart it if its selected pod disappears.



\## Endpoints



| Endpoint | Purpose |

| --- | --- |

| / | Successful HTTP response |

| /health | HTTP health check |

| /metrics | Prometheus metrics |

| /fail | Deliberate HTTP 500 |

| /slow | Deliberate one-second delay |

| /db | Successful SQLite query |

| /db-fail | Deliberate SQL error |



\## Scaling



Edit replicas in terraform/lab.tfvars.



Then plan and apply:



```powershell

terraform -chdir=terraform plan "-var-file=lab.tfvars" "-out=scale.tfplan"

terraform -chdir=terraform apply "scale.tfplan"

```



The local lab allows one to three replicas.



\## Test pod recovery



List pods and choose one application pod:



```powershell

minikube kubectl -- get pods -n devops-lab

```



Delete that pod, replacing POD\_NAME:



```powershell

minikube kubectl -- delete pod POD\_NAME -n devops-lab

minikube kubectl -- get pods -n devops-lab -w

```



The ReplicaSet creates a replacement to maintain the desired count.

Press Ctrl+C to stop watching.



\## Application tests



```powershell

docker build -t practice-app:ci ./app

docker run --rm -v "${PWD}/app/test\_app.py:/app/test\_app.py:ro" --entrypoint python practice-app:ci -m unittest discover -s /app -p test\_app.py

```



Tests verify:

\- Health and metric responses.

\- HTTP failure logs correlated with response request IDs.

\- SQL query failures while database connectivity remains healthy.



Tests use temporary SQLite files.



\## CI



.github/workflows/ci.yml runs on main pushes, pull requests,

and manual dispatch.



It checks Terraform formatting and validity, builds the image,

and runs application tests.



GitHub-hosted runners do not have access to the local Minikube cluster.

The current workflow does not deploy or publish images.



\## Evidence



\- evidence/pod-recovery.txt

\- evidence/terraform-no-changes.txt

\- evidence/two-replicas.txt



The initial no-changes evidence used one replica.

The later scaling evidence shows two ready pods.



\## State and credentials



Terraform state, plans, local variable files, and provider cache

are excluded from Git.



The provider lock file and example variables are committed.

Kubernetes credentials remain in the local kubeconfig.



\## Limitations and next stages



Both replicas run on a single Minikube node.

This does not provide protection against node failure.



Each pod has its own temporary SQLite database and metric counters.

Database contents are not shared or persistent.



The application uses Flask's development server.

Production work would add a suitable application server,

shared persistent storage, stronger security, and operational controls.



Next stages include image publishing, automated deployment,

Kubernetes monitoring, and portfolio documentation.

