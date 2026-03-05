#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

REGION="${AWS_REGION:-us-east-1}"
AWS_CMD=(aws --region "$REGION")

USER_NAME="${USER:-$(id -un)}"
NAME_SUFFIX=""
[[ -n "$CX_TEAM_NAME" ]] && NAME_SUFFIX="-${CX_TEAM_NAME}"
[[ -z "$NAME_SUFFIX" && -n "$CX_LABS_NAME_SUFFIX" ]] && NAME_SUFFIX="-${CX_LABS_NAME_SUFFIX}"
STACK_NAME="cs-${USER_NAME}-ec2-otel${NAME_SUFFIX}"
KEY_NAME="${STACK_NAME}-key"
PEM_PATH="${EC2_OTEL_PEM_PATH:-${SCRIPT_DIR}/${STACK_NAME}.pem}"

echo "> Stack: $STACK_NAME, Key: $KEY_NAME, Region: $REGION"

if ! "${AWS_CMD[@]}" cloudformation describe-stacks --stack-name "$STACK_NAME" &>/dev/null; then
  echo "> Stack does not exist: $STACK_NAME (already deleted or never created)"
else
  echo "> Deleting stack: $STACK_NAME"
  "${AWS_CMD[@]}" cloudformation delete-stack --stack-name "$STACK_NAME"
  echo "> Waiting for stack deletion..."
  "${AWS_CMD[@]}" cloudformation wait stack-delete-complete --stack-name "$STACK_NAME" || true
fi

if "${AWS_CMD[@]}" ec2 describe-key-pairs --key-names "$KEY_NAME" &>/dev/null; then
  echo "> Deleting key pair: $KEY_NAME"
  "${AWS_CMD[@]}" ec2 delete-key-pair --key-name "$KEY_NAME"
else
  echo "> Key pair does not exist: $KEY_NAME"
fi

if [[ -f "$PEM_PATH" ]]; then
  echo "> Consider removing the private key file: $PEM_PATH"
fi
