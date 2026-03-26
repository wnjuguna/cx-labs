TF_DIR=tf
ANSIBLE_DIR=ansible
KIND_CLUSTER_NAME?=cx-labs-kind-local
KUBECONFIG?=$(HOME)/.kube/kind-local.yaml
TF_BIN := $(shell if command -v tofu >/dev/null 2>&1; then echo tofu; elif command -v terraform >/dev/null 2>&1; then echo terraform; fi)
TF_VAR_cx_domain ?= $(if $(CX_DOMAIN),$(CX_DOMAIN),eu2.coralogix.com)
TF_VAR_enable_tiny_telemetry ?= true
TF_VAR_tiny_telemetry_image ?= tiny-telemetry:local
TF_VAR_enable_log_generator ?= true
TF_VAR_log_generator_image ?= log-generator:local
TF_VAR_log_generator_lines_per_sec ?= 5

export KUBECONFIG := $(KUBECONFIG)

up: cluster apply

cluster:
	cd $(ANSIBLE_DIR) && ansible-playbook bootstrap-kind.yaml \
		-e kind_cluster_name=$(KIND_CLUSTER_NAME) \
		-e kubeconfig_path=$(KUBECONFIG) \
		-e tiny_telemetry_image=$(TF_VAR_tiny_telemetry_image) \
		-e log_generator_image=$(TF_VAR_log_generator_image)

apply: check-tf check-cx-key
	cd $(TF_DIR) && TF_VAR_cx_data_key="$(CX_DATA_KEY)" TF_VAR_cx_domain="$(TF_VAR_cx_domain)" TF_VAR_enable_tiny_telemetry="$(TF_VAR_enable_tiny_telemetry)" TF_VAR_tiny_telemetry_image="$(TF_VAR_tiny_telemetry_image)" TF_VAR_enable_log_generator="$(TF_VAR_enable_log_generator)" TF_VAR_log_generator_image="$(TF_VAR_log_generator_image)" TF_VAR_log_generator_lines_per_sec="$(TF_VAR_log_generator_lines_per_sec)" $(TF_BIN) init --upgrade && \
	TF_VAR_cx_data_key="$(CX_DATA_KEY)" TF_VAR_cx_domain="$(TF_VAR_cx_domain)" TF_VAR_enable_tiny_telemetry="$(TF_VAR_enable_tiny_telemetry)" TF_VAR_tiny_telemetry_image="$(TF_VAR_tiny_telemetry_image)" TF_VAR_enable_log_generator="$(TF_VAR_enable_log_generator)" TF_VAR_log_generator_image="$(TF_VAR_log_generator_image)" TF_VAR_log_generator_lines_per_sec="$(TF_VAR_log_generator_lines_per_sec)" $(TF_BIN) apply --auto-approve

plan: check-tf check-cx-key
	cd $(TF_DIR) && TF_VAR_cx_data_key="$(CX_DATA_KEY)" TF_VAR_cx_domain="$(TF_VAR_cx_domain)" TF_VAR_enable_tiny_telemetry="$(TF_VAR_enable_tiny_telemetry)" TF_VAR_tiny_telemetry_image="$(TF_VAR_tiny_telemetry_image)" TF_VAR_enable_log_generator="$(TF_VAR_enable_log_generator)" TF_VAR_log_generator_image="$(TF_VAR_log_generator_image)" TF_VAR_log_generator_lines_per_sec="$(TF_VAR_log_generator_lines_per_sec)" $(TF_BIN) init --upgrade && \
	TF_VAR_cx_data_key="$(CX_DATA_KEY)" TF_VAR_cx_domain="$(TF_VAR_cx_domain)" TF_VAR_enable_tiny_telemetry="$(TF_VAR_enable_tiny_telemetry)" TF_VAR_tiny_telemetry_image="$(TF_VAR_tiny_telemetry_image)" TF_VAR_enable_log_generator="$(TF_VAR_enable_log_generator)" TF_VAR_log_generator_image="$(TF_VAR_log_generator_image)" TF_VAR_log_generator_lines_per_sec="$(TF_VAR_log_generator_lines_per_sec)" $(TF_BIN) plan

destroy: check-tf check-cx-key
	cd $(TF_DIR) && TF_VAR_cx_data_key="$(CX_DATA_KEY)" TF_VAR_cx_domain="$(TF_VAR_cx_domain)" TF_VAR_enable_tiny_telemetry="$(TF_VAR_enable_tiny_telemetry)" TF_VAR_tiny_telemetry_image="$(TF_VAR_tiny_telemetry_image)" TF_VAR_enable_log_generator="$(TF_VAR_enable_log_generator)" TF_VAR_log_generator_image="$(TF_VAR_log_generator_image)" TF_VAR_log_generator_lines_per_sec="$(TF_VAR_log_generator_lines_per_sec)" $(TF_BIN) init --upgrade && \
	TF_VAR_cx_data_key="$(CX_DATA_KEY)" TF_VAR_cx_domain="$(TF_VAR_cx_domain)" TF_VAR_enable_tiny_telemetry="$(TF_VAR_enable_tiny_telemetry)" TF_VAR_tiny_telemetry_image="$(TF_VAR_tiny_telemetry_image)" TF_VAR_enable_log_generator="$(TF_VAR_enable_log_generator)" TF_VAR_log_generator_image="$(TF_VAR_log_generator_image)" TF_VAR_log_generator_lines_per_sec="$(TF_VAR_log_generator_lines_per_sec)" $(TF_BIN) destroy --auto-approve
	cd $(ANSIBLE_DIR) && ansible-playbook destroy-kind.yaml \
		-e kind_cluster_name=$(KIND_CLUSTER_NAME)

workspaces: check-tf
	cd $(TF_DIR) && $(TF_BIN) workspace list

port-forward:
	@echo "UI will be available on http://localhost:8080"
	kubectl --kubeconfig $(KUBECONFIG) --namespace otel-demo port-forward svc/frontend-proxy "8080:8080"

k9s:
	k9s --kubeconfig $(KUBECONFIG)

check-tf:
	@if [ -z "$(TF_BIN)" ]; then \
		echo "Neither tofu nor terraform found in PATH"; \
		exit 1; \
	fi

check-cx-key:
	@if [ -z "$(CX_DATA_KEY)" ]; then \
		echo "Env var CX_DATA_KEY must be set to a Coralogix send-your-data key"; \
		exit 1; \
	fi
