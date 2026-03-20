# lambda-exercise

Creates an S3 bucket, an SQS queue, and two Python Lambda functions:

- **Producer**: Triggered by S3 object creation; calls `list_objects_v2` and `get_object` for each key from the event, performs a small outbound HTTP GET to `https://httpbin.org/get` (for client spans under auto-instrumentation), logs to stdout, then `SendMessage` to SQS with the object key.
- **Consumer**: Triggered by SQS; reads the key from the message, `get_object` from the bucket (single AWS call besides SQS polling), same small HTTP GET to httpbin, logs to stdout.

Lambdas run in the default network (no VPC) so they can reach httpbin. Logging is stdout only; no CloudWatch Logs IAM is configured (Coralogix Lambda telemetry would export traces separately).

Recommended Coralogix integrations for telemetry from this lab:
- `Lambda Auto Instrumentation`
- `AWS Resource Metadata Collection`

## Prerequisites

- AWS CLI configured (credentials and region)
- Optional: `AWS_REGION` (default `eu-north-1`)

## Usage

```bash
# From cx-labs repo root or from lambda-exercise/
cd lambda-exercise
make up      # create stack
make plan    # terraform plan
make destroy # delete stack
```

After `make up`, upload a file to the provisioned bucket to trigger the producer Lambda
(which then sends the key to SQS and triggers the consumer).

To run multiple instances in parallel, set `CX_TEAM_NAME` or `CX_LABS_WORKSPACE_NAME` before `make up` (see main [CX-Labs README](../README.md)).
