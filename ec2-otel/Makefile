# ec2-otel: CloudFormation-based EC2 VM (JPetstore + node_exporter). Key pair is created by cf-up.sh.
# Run from ec2-otel/ with AWS access keys in env (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY) and optional AWS_REGION, CX_TEAM_NAME, CX_LABS_NAME_SUFFIX.

USER_NAME := $(or $(USER),$(shell id -un))
NAME_SUFFIX := $(if $(CX_TEAM_NAME),-$(CX_TEAM_NAME),$(if $(CX_LABS_NAME_SUFFIX),-$(CX_LABS_NAME_SUFFIX),))
STACK_NAME := cs-$(USER_NAME)-ec2-otel$(NAME_SUFFIX)
AWS_REGION ?= us-east-1
AWS_CMD := aws --region $(AWS_REGION)
PEM_PATH ?= $(CURDIR)/$(STACK_NAME).pem

export AWS_REGION

up:
	./cf-up.sh

destroy:
	./cf-down.sh

plan:
	$(AWS_CMD) cloudformation validate-template --template-body file://$(CURDIR)/otel-vm.yaml
	@echo "> Stack name that would be used: $(STACK_NAME)"
	@$(AWS_CMD) cloudformation describe-stacks --stack-name $(STACK_NAME) --query 'Stacks[0].StackStatus' --output text 2>/dev/null || echo "> Stack does not exist yet"

outputs:
	@$(AWS_CMD) cloudformation describe-stacks --stack-name $(STACK_NAME) --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' --output table

ssh:
	@PUBLIC_IP=$$($(AWS_CMD) cloudformation describe-stacks --stack-name $(STACK_NAME) --query 'Stacks[0].Outputs[?OutputKey==`PublicIP`].OutputValue' --output text 2>/dev/null); \
	if [ -z "$$PUBLIC_IP" ]; then echo "> Could not get PublicIP for stack $(STACK_NAME)"; exit 1; fi; \
	if [ ! -f "$(PEM_PATH)" ]; then echo "> PEM not found: $(PEM_PATH)"; exit 1; fi; \
	exec ssh -i "$(PEM_PATH)" -o StrictHostKeyChecking=accept-new ec2-user@$$PUBLIC_IP
