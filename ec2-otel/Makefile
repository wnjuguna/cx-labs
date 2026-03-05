# ec2-otel: Terraform deploys the CF stack (otel-vm.yaml) and key pair. All resources destroyable with tf destroy.
# Run from ec2-otel/ with AWS access keys in env (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY) and optional AWS_REGION, CX_TEAM_NAME, CX_LABS_NAME_SUFFIX.
# SSH key: same as other labs (~/.ssh/id_ed25519 or ~/.ssh/id_rsa); override with AWS_SSH_PRIVKEY when using tf-wrapper.

TF_DIR = tf
PRIVATE_SSH_KEY_PATH ?= $(firstword $(wildcard $(HOME)/.ssh/id_ed25519) $(HOME)/.ssh/id_rsa)

export AWS_REGION

up:
	../common/tf-wrapper.sh $(TF_DIR) up ec2-otel

destroy:
	../common/tf-wrapper.sh $(TF_DIR) down ec2-otel

plan:
	../common/tf-wrapper.sh $(TF_DIR) plan ec2-otel

outputs:
	@cd $(TF_DIR) && (terraform output 2>/dev/null || tofu output 2>/dev/null)

ssh:
	@IP=$$(cd $(TF_DIR) && (terraform output -raw public_ip 2>/dev/null || tofu output -raw public_ip 2>/dev/null)); \
	if [ -z "$$IP" ]; then echo "> No public_ip output; run make up first"; exit 1; fi; \
	if [ ! -f "$(PRIVATE_SSH_KEY_PATH)" ]; then echo "> Private key not found: $(PRIVATE_SSH_KEY_PATH)"; exit 1; fi; \
	exec ssh -i "$(PRIVATE_SSH_KEY_PATH)" -o StrictHostKeyChecking=accept-new ec2-user@$$IP

workspaces:
	../common/tf-wrapper.sh $(TF_DIR) workspaces ec2-otel
