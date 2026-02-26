TF_DIR=tf

# Bring up ECS Fargate cluster and deploy jpetstore + OTEL stack (CloudFormation)
up: cluster

# Create ECS cluster and deploy the CloudFormation template (task definition, service, roles, etc.)
cluster:
	../common/tf-wrapper.sh $(TF_DIR) up ecs-fargate

destroy:
	../common/tf-wrapper.sh $(TF_DIR) down

plan:
	../common/tf-wrapper.sh $(TF_DIR) plan ecs-fargate

workspaces:
	../common/tf-wrapper.sh $(TF_DIR) workspaces ecs-fargate
