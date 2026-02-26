# ecs-fargate

Creates an ECS Fargate cluster and deploys the jpetstore + OpenTelemetry stack via CloudFormation. The stack is based on `integrations/otel/ecs-fargate/task-definition.yaml` and includes:

- ECS cluster (created by Terraform)
- CloudFormation stack: task definition (jpetstore + OTEL Java agent init + OTEL collector), ECS service, IAM roles, security group, SSM parameter for collector config

## Prerequisites

- AWS CLI configured (credentials and region)
- `CX_DATA_TOKEN` – Coralogix Send-Your-Data API key
- Optional: `CX_DOMAIN` (default `eu2.coralogix.com`), `AWS_REGION` (default `eu-north-1`)

The lab uses the **default VPC** and its subnets. Ensure a default VPC exists in the target region.

## Usage

```bash
# From cx-labs repo root or from ecs-fargate/
cd ecs-fargate
make up      # create cluster and deploy stack
make plan    # terraform plan
make destroy # delete stack and cluster
```

To run multiple instances in parallel, set `CX_TEAM_NAME` or `CX_LABS_WORKSPACE_NAME` before `make up` (see main [CX-Labs README](../README.md)).
