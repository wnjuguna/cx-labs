TF_DIR=tf

up: cluster

cluster:
	../common/tf-wrapper.sh $(TF_DIR) up lambda-exercise

destroy:
	../common/tf-wrapper.sh $(TF_DIR) down

plan:
	../common/tf-wrapper.sh $(TF_DIR) plan lambda-exercise

workspaces:
	../common/tf-wrapper.sh $(TF_DIR) workspaces lambda-exercise
