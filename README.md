\# DevOps Platform Lab



A Kubernetes learning project using Terraform, Docker,

GitHub Actions, and GitHub Container Registry.



\## Current implementation



\- Instrumented Python application with HTTP and SQLite endpoints.

\- Local Minikube Kubernetes cluster.

\- Terraform-managed namespace, Deployment, and Service.

\- Two application replicas.

\- Readiness and liveness probes.

\- CPU and memory requests and limits.

\- Three automated application behavior tests.

\- Terraform validation and container builds in GitHub Actions.

\- Publishing tested images to GitHub Container Registry.

\- Automated deployment verification in a temporary Kubernetes cluster.

\- Evidence of pod replacement, scaling, and CI deployment.



Terraform manages resources inside an existing cluster.

Minikube creates the cluster locally and in the deployment-test workflow.



\## Requirements



\- Docker Desktop with Linux containers.

\- Minikube.

\- Terraform 1.12 or newer, below 2.0.

\- PowerShell.

\- Internet access for initial downloads.



Tested locally with Minikube 1.38.1, Kubernetes 1.35.1,

and Terraform 1.12.2.



Use `minikube kubectl --` to run a client matching the cluster.



\## Start the cluster



Run from the project root:



```powershell

minikube start

minikube kubectl -- get nodes

```



\## Build the local application image



```powershell

minikube image build -t practice-app:v1 ./app

```



The local deployment uses this image inside Minikube.

The CI workflow separately builds and publishes commit-tagged images.



\## Deploy with Terraform



For a fresh local setup:



```powershell

Copy-Item .\\terraform\\lab.example.tfvars .\\terraform\\lab.tfvars

terraform -chdir=terraform init

terraform -chdir=terraform validate

terraform -chdir=terraform plan "-var-file=lab.tfvars" "-out=deploy.tfplan"

terraform -chdir=terraform apply "deploy.tfplan"

```



Copy the example variables only during initial setup.

Keep existing local variable changes on subsequent runs.



Terraform creates the namespace, Deployment, and Service.



If the devops-lab resources already exist but are absent from Terraform

state, import them first:



```powershell

terraform -chdir=terraform import kubernetes\_namespace\_v1.lab devops-lab

terraform -chdir=terraform import kubernetes\_deployment\_v1.app devops-lab/practice-app

terraform -chdir=terraform import kubernetes\_service\_v1.app devops-lab/practice-app

```



Review the plan after importing before applying any differences.



Terraform is the source of truth for these resources.

`k8s/app.yml` is the initial bootstrap reference, with one replica.

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



Edit `replicas` in `terraform/lab.tfvars`.



Then plan and apply:



```powershell

terraform -chdir=terraform plan "-var-file=lab.tfvars" "-out=scale.tfplan"

terraform -chdir=terraform apply "scale.tfplan"

```



The local lab allows one to three replicas.

Continue using the variable file to retain the chosen replica count.



\## Test pod recovery



List pods and choose one application pod:



```powershell

minikube kubectl -- get pods -n devops-lab

```



Delete that pod, replacing `POD\_NAME`:



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

All three tests passed locally and in CI.



\## CI and deployment verification



`.github/workflows/ci.yml` contains three sequential jobs:



1\. \*\*Validate Terraform:\*\* checks formatting and configuration.

2\. \*\*Build, test and publish image:\*\* builds the image, runs application

&#x20;  tests, and publishes the tested image to GitHub Container Registry.

3\. \*\*Test Kubernetes deployment:\*\* creates a temporary Minikube cluster,

&#x20;  deploys the published image with Terraform, and checks HTTP health

&#x20;  and database responses.



Pull requests and manual runs execute validation, builds, and tests.

Pushes to main also publish images and run deployment verification.



Images use this naming pattern:



&#x20;   ghcr.io/nomansahi/devops-platform:<git-commit-sha>



The commit tag identifies the source version.

The deployment test downloads that published image and loads it

into its temporary cluster.



The workflow uses Ubuntu 24.04 runners and Terraform 1.12.2.

Registry access uses the workflow's built-in GitHub token.



The deployment job uploads resource and event diagnostics,

then removes its temporary cluster.



All three jobs passed during verification.



This workflow verifies deployment in a temporary environment.

It does not automatically update the local Minikube cluster

or maintain a persistent production environment.



\## Evidence



\- `evidence/pod-recovery.txt`: replacement pod after deletion.

\- `evidence/terraform-no-changes.txt`: configuration matched imported resources.

\- `evidence/two-replicas.txt`: two ready local application pods.

\- `evidence/published-image.txt`: first published image reference.

\- `evidence/ci-deployment/resources.txt`: CI Kubernetes resource listing.

\- `evidence/ci-deployment/events.txt`: CI Kubernetes events.



The initial no-changes evidence used one replica.

The later scaling evidence shows two ready pods.



The published-image file records an earlier successful publication.

Subsequent commits produce new image tags shown in their Actions summaries.



\## State and credentials



Terraform state, plans, local variable files, and provider cache

are excluded from Git.



The provider lock file and example variables are committed.

Local Kubernetes credentials remain in the kubeconfig.



Local Terraform state must be retained to manage existing resources.

The CI deployment uses temporary state for its temporary cluster.



\## Limitations and next stages



Both local replicas run on a single Minikube node.

This does not provide protection against node failure.



Each pod has its own temporary SQLite database and metric counters.

Database contents are not shared or persistent.



The application uses Flask's development server.

Production work would add a suitable application server,

shared persistent storage, stronger security, and operational controls.



Next stages include Kubernetes monitoring, deployment to a persistent

environment, and portfolio documentation.

