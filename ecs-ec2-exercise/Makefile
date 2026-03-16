TF_DIR=tf

# Bring up ECS EC2 cluster and deploy jpetstore via CloudFormation (like ecs-fargate-exercise)
up: cluster

cluster:
	../common/tf-wrapper.sh $(TF_DIR) up ecs-ec2-exercise

destroy:
	../common/tf-wrapper.sh $(TF_DIR) down ecs-ec2-exercise

plan:
	../common/tf-wrapper.sh $(TF_DIR) plan ecs-ec2-exercise

workspaces:
	../common/tf-wrapper.sh $(TF_DIR) workspaces ecs-ec2-exercise
