# ecs-ec2-exercise

Terraform deploys a single CloudFormation template that creates the ECS/EC2 cluster and the jpetstore application. One **t3.large** instance is used for the lab cluster.

## Details

- The EC2 host IP is discovered dynamically using the IMDS v1 endpoint. `OTEL_EXPORTER_OTLP_ENDPOINT` is set to `http://$HOST_IP:4318`.
- The application container uses **bridge** networking.
- The S3 bucket required by the Coralogix ECS/EC2 integration is created by this installation.
- The jpetstore application is reachable at `http://<public-ip>:8080/jpetstore` (use the EC2 instance's public IP).
- Install the Coralogix ECS/EC2 integration to ship telemetry to Coralogix.

## Prerequisites

- `CX_DATA_TOKEN` – Coralogix Send-Your-Data API key
- `AWS_REGION` (default `eu-north-1`)
- Optional: `CX_DOMAIN` (default `eu2.coralogix.com`)

The lab uses the **default VPC** and its subnets. Ensure a default VPC exists in the target region. To reach jpetstore at the URL above, the instance needs a public IP (e.g. use default VPC public subnets).

## Usage

```bash
cd ecs-ec2-exercise
make up      # deploy CloudFormation stack (cluster + jpetstore)
make plan    # terraform plan
make destroy # delete stack and all resources
```

To run multiple instances in parallel, set `CX_TEAM_NAME` or `CX_LABS_WORKSPACE_NAME` before `make up` (see main [CX-Labs README](../README.md)).