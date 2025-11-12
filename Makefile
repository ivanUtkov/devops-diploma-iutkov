SHELL := /bin/bash

infra-init:
	@cd infra && terraform init

infra-apply:
	@export TF_VAR_cloud_id=$$(yc config get cloud-id) ; \
	export TF_VAR_folder_id=$$(yc config get folder-id) ; \
	export TF_VAR_zone=$$(yc config get compute-default-zone) ; \
	cd infra && terraform apply -auto-approve

infra-up: infra-init infra-apply

infra-destroy:
	@export TF_VAR_cloud_id=$$(yc config get cloud-id) ; \
	export TF_VAR_folder_id=$$(yc config get folder-id) ; \
	export TF_VAR_zone=$$(yc config get compute-default-zone) ; \
	cd infra && terraform destroy -auto-approve
