# ecs-ec2-exercise

Similar to **ecs-fargate-exercise**: Terraform deploys a single CloudFormation template that creates the ECS/EC2 cluster and the jpetstore application. One **t3.large** instance is used for the lab cluster. Tasks use **awsvpc** networking (task-level security group for app and OTLP ports). No Parameter Store or extra Task Execution Role permissions.

## Prerequisites

- AWS CLI configured (credentials and region)
- `CX_DATA_TOKEN` – Coralogix Send-Your-Data API key
- Optional: `CX_DOMAIN` (default `eu2.coralogix.com`), `AWS_REGION` (default `eu-north-1`)

The lab uses the **default VPC** and its subnets. Ensure a default VPC exists in the target region.

## Usage

```bash
cd ecs-ec2-exercise
make up      # deploy CloudFormation stack (cluster + jpetstore)
make plan    # terraform plan
make destroy # delete stack and all resources
```

To run multiple instances in parallel, set `CX_TEAM_NAME` or `CX_LABS_WORKSPACE_NAME` before `make up` (see main [CX-Labs README](../README.md)).
