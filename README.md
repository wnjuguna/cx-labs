# CX-Labs

Some scripts/tools for quickly bringing up infrastructure to play with Coralogix and OTel in AWS

# Requirements

You will need some tools:

- python3, Docker Desktop and ansible-playbook
- make
- opentofu or terraform
- kind, helm, kubectl and k9s for Kubernetes things
- `git` (for `kind-local` to clone [tiny-telemetry](https://github.com/BigRedS/tiny-telemetry) into a cache dir)

On a mac, you can probably do

```
brew install ansible make opentofu terraform kubectl k9s helm kind awscli python git
```

You'll also need to auth with AWS and paste the tokens into your shell.

And to set some environment vars defining the Coralogix team you want to send data to:

- `CX_DATA_TOKEN`: a send-your-data token for the team
- `CX_DOMAIN`: the domain for your team for host- and helm-based labs (eks, k3s-ec2, postgres), 'eu2.coralogix.com' is the default
- `CX_REGION`: the CX region for the ECS instrumentation
- `AWS_REGION`: the AWS region to bring stuff up in; defaults to `eu-north-1`

There's also an optional environment variable:

- `CX_TEAM_NAME`: the name of the team, if this is set a terraform workspace is created with the value as its name, it is
appened as a suffix onto the names of resources, and added to the default tags of resources.

The `cx` tool will set these automatically for you: `cx avi-lab exec make up` should just do what you expect, assuming you have a data key configured for `avi-lab`.

Finally, for the VM-based labs (k3s-ec2, postgres), you'll also need an ssh key at `~/.ssh/id_rsa` or `~/.ssh/id_ed25519`; feel free to patch `./common/tf-wrapper.sh` if yours is elsewhere.

# How to use

There is a subdirectory for each type of lab, each of which has a Makefile defining the things you can do with that type of lab. In the simplest use cases:

cd to the directory of the thing you want and run

```
make up
```

to bring the lab up, and

```
make destroy
```

to destroy it. See below for more options.

## k3s-ec2

This will bring up a single-node K3s cluster on an EC2 VM. It's much faster to bring up and
requires fewer resources than EKS so is good when you don't need anything EKS-specific

- `make up` - create the vm, install k3s, otel-demo and coralogix
- `make destroy` - delete the vm
- `make vm` create the VM and install k3s
- `make cx` - install the CX helm chart
- `make values` - install the CX helm chart using `./values.yaml` as the values file
- `make port-forward` - set up a port-forward to reach the otel-demo frontend at [http://localhost:8080](http://localhost:8080)
- `make k9s` - open K9s on the cluster

Terraform brings up the VM, creating a securitygroup and ssh keypair, then ansible installs k3s, and helm installs the otel-demo and the coralogix charts

## kind-local

This brings up a single-node local kind cluster, then installs Coralogix otel-integration and optionally otel-demo.

Pre-requisites:

1. Install [Docker Desktop](https://www.docker.com/products/docker-desktop/). (optional: set Docker's memory limit to 8GB)
2. Before first run in change directory into `kind-local/ansible`, install the required Ansible
collection:

```
cd kind-local/ansible
ansible-galaxy collection install -r requirements.yml
```
3. Proceed with commands to create the lab.

Commands:

The commands should be run in the `kind-local` directory

- `make up` - bootstrap local tools, ensure kind cluster exists, then apply Terraform/OpenTofu for in-cluster resources
- `make apply` - redeploy otel-integration, reapplying override file
- `make destroy` - destroy Terraform/OpenTofu-managed in-cluster resources, then delete the kind cluster
- `make port-forward` - set up a port-forward to reach the otel-demo frontend at [http://localhost:8080](http://localhost:8080) (if otel-demo is enabled)
- `make k9s` - open K9s on the local cluster


**Ansible** sets up the local lab:

1. Installs kind and related tools.
2. The lab wires in two generators:
    1.  **[tiny-telemetry](https://github.com/BigRedS/tiny-telemetry)** — one image that drives OpenTelemetry traces (spans) that look like calls between microservices (HTTP-style, distributed trace shape).
    2.  **log-generator** — reads `*.log` files under `kind-local/logs/` and emits a steady stream of log lines (UTF-8) to stdout for ingestion.

Disable tiny-telemetry with:   

```
cd kind-local
TF_VAR_enable_tiny_telemetry=false make apply
```

Enable `otel-demo` with:

```
cd kind-local
TF_VAR_enable_otel_demo=true make apply
```

## eks

This will bring up an EKS cluster, by default on 1-3 t3.medium nodes.

- `make up` - bring up the cluster, install otel-demo and coralogix
- `make destroy` - destroy the cluster
- `make cx` - install the CX helm chart
- `make values` - install the CX helm chart using `./values.yaml` as the values file
- `make port-forward` - set up a port-forward to reach the otel-demo frontend at [http://localhost:8080](http://localhost:8080)
- `make k9s` - open K9s on the cluster

Terraform brings up the cluster using the `eks` module, then helm installs the otel-demo and coralogix charts

The EKS version is by default set to the latest from AWS (queried via awscli), set the
'EKS_VERSION' environment variable to a specific version if you'd prefer that. If AWS
release a new version while your cluster is running, a successive `make up` will upgrade
it without prompting, use `make plan` to check first if this is important to you.

## ecs-ec2

This will bring up an ecs-ec2 cluster running the Coralogix ECS integration and an instance of tiny-telemetry
to generate nonsense telemetry: [https://github.com/BigRedS/tiny-telemetry](https://github.com/BigRedS/tiny-telemetry)

- `make up` - create the cluster, install the workloads
- `make destroy` - delete the cluster

The task definition for tiny-telemetry is in `tf/tiny_telemetry_task.tf`; delete this to not-provision it, and
replace with your own task def if you've any other workloads you'd like to run instead.

## ecs-fargate

Brings up an ECS Fargate cluster and deploys the jpetstore + OpenTelemetry stack via
CloudFormation (task definition, service, OTEL collector, IAM roles, SSM parameter).
Uses the default VPC and subnets. Data is sent to Coralogix using `CX_DATA_TOKEN` and
`CX_DOMAIN` (region is derived from the domain, e.g. eu2.coralogix.com → EU2).

- `make up` - create the ECS cluster and deploy the CloudFormation stack (jpetstore + OTEL)
- `make destroy` - delete the stack and cluster
- `make plan` - terraform plan
- `make workspaces` - list terraform workspaces

Requires `CX_DATA_TOKEN` and optionally `CX_DOMAIN` and `AWS_REGION`. No SSH key needed.

## postgres

Brings up George Pickers' Tracey Reloaded: [https://github.com/georgep1ckers/tracey-reloaded](https://github.com/georgep1ckers/tracey-reloaded)

- `make up` - create the vm, install k3s, Tracey Reloaded and coralogx
- `make destroy` - delete the VM
- `make vm` - create the VM and install k3s
- `make cx` - install the CX helm chart on k3s
- `make postgres` - install tracey-reloaded on k3s
- `make k9s` - open K9s on the cluster

# Running labs in parallel

If the `CX_TEAM_NAME` or `CX_LABS_WORKSPACE_NAME` environment variable is set, then it will be used to name a tf
workspace for the purpose, giving you the option of running two instances of the same lab in parallel without the
plans interfering with each other.

```
CX_TEAM_NAME=acmecorp make up
CX_TEAM_NAME=megacorp make up
```

Will bring up one instance of the lab in an 'acmecorp' workspace with (most of) the resources named with a suffix
of 'acmecorp', and another in the 'megacorp' workspace with that as the suffix. `CX_LABS_WORKSPACE_NAME` won't affect
resource names and just sets the workspace name.

The expected way of setting these is to use the cx tool:

```
cx acmecorp exec make up
cx megacorp exec make up
```

which will also configure the collector to send data to acmecorp's and megacorp's coralogix instances by default.

When a lab is brought down (`make destroy`) the workspace is deleted.

The script `common/list-workspaces.sh` will iterate over each lab and print all the extant workspaces, as a way
of keeping track of what is running. Run it from the root of the repo.

# Underlying principles

- Terraform/OpenTofu is responsible for all the AWS resources; everything needs to be destroyable
with a `tf destroy`
- Anything done to the brought-up resources is idempotent; there's nothing wrong with just
rerunning stuff until it works
- In general, shell scripts are ideal for configuring the remote host, Ansible for anything more
than a little complex. Nested conditionals are more than a little complex :)
- A large collection of simple things is easier to reason about and debug than a small set of large
and complex custom ones
- As much as possible is configured using environment variables, and especially those that already
exist. The `cx` tool creates a whole environment for a tenant (`$CX_TEAM_NAME`, `$CX_DATA_TOKEN`
etc. ) so we use those, and others are just hanging around usefully (`$USER` is often
firstname.surname, identifying enough to use for the `owner` label)
- Speed of bringing up and tearing down is second only to the specific reliability there; code
repetition's *fine* if it helps with that, this isn't a big maintainable codebase. Equally,
abstracting these into TF modules just adds complexity that's not needed

# Limitations/todo list

- kubeconfigs are not cleared out by a destroy
- ssh key discovery is crap
- literally zero attempt to notice missing dependencies before they get used
- k8s version is hardcoded in the EKS tf; should probably be set as a variable by some call to awscli?
- k3s-ec2 does not deal well with the VM rebooting
- May need to remove the disk-pressure taint from k3s
- Sometimes ansible tries to connect before the VM is up; it'd be good to make it auto-retry

