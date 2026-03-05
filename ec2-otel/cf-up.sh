#!/bin/bash
set -e

# Run from ec2-otel directory (e.g. via make from ec2-otel/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
TEMPLATE_FILE="${SCRIPT_DIR}/otel-vm.yaml"

if [[ ! -f "$TEMPLATE_FILE" ]]; then
  echo "> Template not found: $TEMPLATE_FILE"
  exit 1
fi

if [[ -z "$AWS_ACCESS_KEY_ID" ]]; then
  echo "> No AWS credentials found; set AWS_ACCESS_KEY_ID (and AWS_SECRET_ACCESS_KEY) and try again."
  exit 1
fi

# Region for AWS CLI (same auth approach as other cx-labs: access keys from env)
REGION="${AWS_REGION:-us-east-1}"
AWS_CMD=(aws --region "$REGION")

# Stack and key naming: cs-${USER}-ec2-otel[-suffix]
USER_NAME="${USER:-$(id -un)}"
NAME_SUFFIX=""
[[ -n "$CX_TEAM_NAME" ]] && NAME_SUFFIX="-${CX_TEAM_NAME}"
[[ -z "$NAME_SUFFIX" && -n "$CX_LABS_NAME_SUFFIX" ]] && NAME_SUFFIX="-${CX_LABS_NAME_SUFFIX}"
STACK_NAME="cs-${USER_NAME}-ec2-otel${NAME_SUFFIX}"
KEY_NAME="${STACK_NAME}-key"

# PEM path: EC2_OTEL_PEM_PATH or default under script dir
PEM_PATH="${EC2_OTEL_PEM_PATH:-${SCRIPT_DIR}/${STACK_NAME}.pem}"

# Tags for create-key-pair
OWNER_TAG="${CX_OWNER_EMAIL:-${USER_NAME}@coralogix.com}"
PROJECT_TAG="${CX_PROJECT:-cs-boston}"

echo "> Stack: $STACK_NAME, Key: $KEY_NAME, Region: $REGION"
echo "> PEM will be written to: $PEM_PATH"

# Ensure key pair exists; create and save PEM if not
if ! "${AWS_CMD[@]}" ec2 describe-key-pairs --key-names "$KEY_NAME" &>/dev/null; then
  echo "> Creating key pair: $KEY_NAME"
  "${AWS_CMD[@]}" ec2 create-key-pair \
    --key-name "$KEY_NAME" \
    --tag-specifications "ResourceType=key-pair,Tags=[{Key=Owner,Value=${OWNER_TAG}},{Key=Project,Value=${PROJECT_TAG}}]" \
    --query 'KeyMaterial' --output text > "$PEM_PATH"
  chmod 600 "$PEM_PATH"
  echo "> Saved private key to $PEM_PATH"
else
  echo "> Key pair already exists: $KEY_NAME (ensure you have the PEM at $PEM_PATH for SSH)"
fi

# Deploy or update stack
if "${AWS_CMD[@]}" cloudformation describe-stacks --stack-name "$STACK_NAME" &>/dev/null; then
  echo "> Updating stack: $STACK_NAME"
  "${AWS_CMD[@]}" cloudformation update-stack \
    --stack-name "$STACK_NAME" \
    --template-body "file://${TEMPLATE_FILE}" \
    --parameters "ParameterKey=KeyName,ParameterValue=${KEY_NAME}" 2>/dev/null || true
  # update-stack returns 0 only when an update is in progress; no update yields validation error
  WAIT_ACTION="stack-update-complete"
else
  echo "> Creating stack: $STACK_NAME"
  "${AWS_CMD[@]}" cloudformation create-stack \
    --stack-name "$STACK_NAME" \
    --template-body "file://${TEMPLATE_FILE}" \
    --parameters "ParameterKey=KeyName,ParameterValue=${KEY_NAME}"
  WAIT_ACTION="stack-create-complete"
fi

echo "> Waiting for stack to reach ${WAIT_ACTION}..."
"${AWS_CMD[@]}" cloudformation wait "$WAIT_ACTION" --stack-name "$STACK_NAME" 2>/dev/null || true

# Show outputs
echo ""
echo "> Stack outputs:"
"${AWS_CMD[@]}" cloudformation describe-stacks --stack-name "$STACK_NAME" \
  --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' --output table
echo ""
echo "> SSH example: ssh -i $PEM_PATH ec2-user@<PublicIP>"
