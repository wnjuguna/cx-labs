TF_DIR=tf

up: cluster

cluster:
	../common/tf-wrapper.sh $(TF_DIR) up ecs-ec2

destroy:
	../common/tf-wrapper.sh $(TF_DIR) down

plan:
	../common/tf-wrapper.sh $(TF_DIR) plan ecs-ec2

workspaces:
	../common/tf-wrapper.sh $(TF_DIR) workspaces ecs-ec2
