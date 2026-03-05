# CX-Labs

Some scripts/tools for quickly bringing up infrastructure to play with Coralogix and OTel in AWS

# Requirements
You will need some tools:

* ansible-playbook
* make
* opentofu or terraform
* helm, kubectl and k9s for Kubernetes things

On a mac, you can probably do

    brew install ansible make opentofu kubectl k9s helm awscli

You'll also need to auth with AWS and paste the tokens into your shell.

And to set some environment vars defining the Coralogix team you want to send data to:

* `CX_DATA_TOKEN`: a send-your-data token for the team
* `CX_DOMAIN`: the domain for your team, 'eu2.coralogix.com' is the default
* `AWS_REGION`: the AWS region to bring stuff up in; defaults to `eu-north-1`

There's also an optional environment variable:

* `CX_TEAM_NAME`: the name of the team, if this is set a terraform workspace is created with the value as its name, it is
  appened as a suffix onto the names of resources, and added to the default tags of resources.

Finally, for the EC2-based jobs, you'll also need an ssh key at `~/.ssh/id_rsa` or `~/.ssh/id_ed25519`; feel free to patch `./common/tf-wrapper.sh` if yours is elsewhere :D

# How to use

There is a subdirectory for each type of lab, each of which has a Makefile defining the things you can do with that type of lab. In the simplest use cases:

cd to the directory of the thing you want and run

    make up

to bring the lab up, and

    make destroy

to destroy it. See below for more options.

## k3s-ec2

This will bring up a single-node K3s cluster on an EC2 VM. It's much faster to bring up and
requires fewer resources than EKS so is good when you don't need anything EKS-specific

* `make up` - create the vm, install k3s, otel-demo and coralogix
* `make destroy` - delete the vm
* `make vm` create the VM and install k3s
* `make cx` - install the CX helm chart
* `make values` - install the CX helm chart using `./values.yaml` as the values file
* `make port-forward` - set up a port-forward to reach the otel-demo frontend at http://localhost:8080
* `make k9s` - open K9s on the cluster

Terraform brings up the VM, creating a securitygroup and ssh keypair, then ansible installs k3s, and helm installs the otel-demo and the coralogix charts

## eks

This will bring up an EKS cluster, by default on 1-3 t3.medium nodes.

* `make up` - bring up the cluster, install otel-demo and coralogix
* `make destroy` - destroy the cluster
* `make cx` - install the CX helm chart
* `make values` - install the CX helm chart using `./values.yaml` as the values file
* `make port-forward` - set up a port-forward to reach the otel-demo frontend at http://localhost:8080
* `make k9s` - open K9s on the cluster

Terraform brings up the cluster using the `eks` module, then helm installs the otel-demo and coralogix charts

The EKS version is by default set to the latest from AWS (queried via awscli), set the
'EKS_VERSION' environment variable to a specific version if you'd prefer that. If AWS
release a new version while your cluster is running, a successive `make up` will upgrade
it without prompting, use `make plan` to check first if this is important to you.

## postgres

Brings up George Pickers' Tracey Reloaded: https://github.com/georgep1ckers/tracey-reloaded

* `make up` - create the vm, install k3s, Tracey Reloaded and coralogx
* `make destroy` - delete the VM
* `make vm` - create the VM and install k3s
* `make cx` - install the CX helm chart on k3s
* `make postgres` - install tracey-reloaded on k3s
* `make k9s` - open K9s on the cluster

## ec2-otel

Brings up an EC2 instance (Amazon Linux 2) with JPetstore (OTel-instrumented), node_exporter, and SSH/HTTP access via CloudFormation. The key pair required by the template is created automatically by `make up` and the private key is saved under `ec2-otel/` (or `EC2_OTEL_PEM_PATH` if set). On `make destroy`, the stack and the key pair are deleted.

* `make up` - create EC2 key pair (if missing), save PEM, deploy CloudFormation stack
* `make destroy` - delete the stack, then delete the key pair
* `make plan` - validate template and show stack status
* `make outputs` - print stack outputs (InstanceId, PublicIP)
* `make ssh` - SSH into the instance using the saved PEM

Environment variables: `AWS_REGION` (default `us-east-1`), `AWS_PROFILE`, `USER`; optional `CX_TEAM_NAME` or `CX_LABS_NAME_SUFFIX` for stack/key naming; optional `CX_OWNER_EMAIL`, `CX_PROJECT` for key-pair tags; `EC2_OTEL_PEM_PATH` to override the PEM file location.

# Running labs in parallel

If the `CX_TEAM_NAME` or `CX_LABS_WORKSPACE_NAME` environment variable is set, then it will be used to name a tf
workspace for the purpose, giving you the option of running two instances of the same lab in parallel without the
plans interfering with each other.

    CX_TEAM_NAME=acmecorp make up
    CX_TEAM_NAME=megacorp make up

Will bring up one instance of the lab in an 'acmecorp' workspace with (most of) the resources named with a suffix
of 'acmecorp', and another in the 'megacorp' workspace with that as the suffix. `CX_LABS_WORKSPACE_NAME` won't affect
resource names and just sets the workspace name.

The expected way of setting these is to use the cx tool:

    cx acmecorp exec make up
    cx megacorp exec make up

which will also configure the collector to send data to acmecorp's and megacorp's coralogix instances by default.

When a lab is brought down (`make destroy`) the workspace is deleted.

The script `common/list-workspaces.sh` will iterate over each lab and print all the extant workspaces, as a way
of keeping track of what is running. Run it from the root of the repo.

# Underlying principles

* Terraform/OpenTofu is responsible for all the AWS resources; everything needs to be destroyable
  with a `tf destroy`

* Anything done to the brought-up resources is idempotent; there's nothing wrong with just
  rerunning stuff until it works

* In general, shell scripts are ideal for configuring the remote host, Ansible for anything more
  than a little complex. Nested conditionals are more than a little complex :)

* A large collection of simple things is easier to reason about and debug than a small set of large
  and complex custom ones

* As much as possible is configured using environment variables, and especially those that already
  exist. The `cx` tool creates a whole environment for a tenant (`$CX_TEAM_NAME`, `$CX_DATA_TOKEN`
  etc. ) so we use those, and others are just hanging around usefully (`$USER` is often
  firstname.surname, identifying enough to use for the `owner` label)

* Speed of bringing up and tearing down is second only to the specific reliability there; code
  repetition's _fine_ if it helps with that, this isn't a big maintainable codebase. Equally,
  abstracting these into TF modules just adds complexity that's not needed

# Limitations/todo list

* kubeconfigs are not cleared out by a destroy

* ssh key discovery is crap

* literally zero attempt to notice missing dependencies before they get used

* k8s version is hardcoded in the EKS tf; should probably be set as a variable by some call to awscli?

* k3s-ec2 does not deal well with the VM rebooting

* May need to remove the disk-pressure taint from k3s

* Sometimes ansible tries to connect before the VM is up; it'd be good to make it auto-retry
