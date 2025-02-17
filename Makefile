ifeq ($(SHELL),/bin/sh)
	SHELL:=/bin/bash
endif

DEBUG ?= -
ifeq (true,$(DEBUG))
  AUTO_APPROVE =
  OUTPUT_SUPPRESSOR =
else
  AUTO_APPROVE = -auto-approve
  OUTPUT_SUPPRESSOR = 1>/dev/null
endif

.PHONY: one-click-mlflow
one-click-mlflow: welcome dependencies-checks pre-requisites set-config deploy goodbye

.PHONY: my_deploy
my_deploy: apply goodbye

.PHONY: deploy
deploy: docker apply

.PHONY: apply
apply: init-terraform import-oauth-stuff apply-terraform

.PHONY: destroy
destroy: init-terraform destroy-terraform


#################
#   TERRAFORM   #
#################

.PHONY: init-terraform
init-terraform:
	@echo "Initializing Terraform..."
	@source vars && cd IaC && rm -rf .terraform && terraform init -backend-config="bucket=$${TF_VAR_backend_bucket}" $(OUTPUT_SUPPRESSOR)
	@echo "Done"
	@echo


.PHONY: apply-terraform
apply-terraform:
	@echo "Deploying infrastructure..."
	@echo "This should take about 20 minutes, don't forget to stretch and hydrate ☕️"
	@source vars && cd IaC && terraform apply $(AUTO_APPROVE) $(OUTPUT_SUPPRESSOR)
	@echo "Done"
	@echo

.PHONY: destroy-terraform
destroy-terraform:
	@echo "Destroying deployed infrastructure..."
	@source vars && cd IaC && terraform destroy $(AUTO_APPROVE) $(OUTPUT_SUPPRESSOR)
	@echo "Done"
	@echo

.PHONY: pre-requisites
pre-requisites: init-config set-project
	@echo "Setting up your GCP project..."
	@source vars && cd IaC/prerequesites && terraform init $(OUTPUT_SUPPRESSOR) && terraform apply $(AUTO_APPROVE) $(OUTPUT_SUPPRESSOR)
	@echo "Done"
	@echo

#################
#    CONFIG     #
#################

.PHONY: set-config
set-config: set_app_engine set-various set-network set-support-email set-users

.PHONY: set_app_engine
set_app_engine:
	@cd bin && ./set_app_engine.sh

.PHONY: set-various
set-various:
	@chmod +x ./bin/set_various.sh
	@cd bin && ./set_various.sh

.PHONY: set-network
set-network:
	@chmod +x ./bin/set_network.sh
	@cd bin && ./set_network.sh

.PHONY: set-support-email
set-support-email:
	@chmod +x ./bin/set_support_email.sh
	@cd bin && ./set_support_email.sh

.PHONY: set-users
set-users:
	@chmod +x ./bin/set_users.sh
	@cd bin && ./set_users.sh

.PHONY: init-config
init-config:
	@chmod +x ./bin/init_conf.sh
	@cd bin && ./init_conf.sh

.PHONY: import-oauth-stuff
import-oauth-stuff:
	@cd bin && ./oauth_stuff_import.sh

.PHONY: set-project
set-project:
	@chmod +x ./bin/set_project.sh
	@cd bin && ./set_project.sh


#################
#     MISC      #
#################

.PHONY: docker
docker:
	@echo
	@echo "Remotely building mlflow server docker image"
	@source vars && gcloud builds submit --tag $${TF_VAR_mlflow_docker_image} ./tracking_server $(OUTPUT_SUPPRESSOR)
	@echo "Done"
	@echo

.PHONY: welcome
welcome:
	@echo
	@echo "Welcome to the GCP Mlflow deployment helper!"
	@echo "If everything goes according to plan, you should have an up and running secure MLFlow install on your project in about 30 minutes"
	@echo

.PHONY: dependencies-checks
dependencies-checks:
	@chmod +x ./bin/check_dependencies.sh
	@cd bin && ./check_dependencies.sh

.PHONY: goodbye
goodbye:
	@echo
	@echo "Congratulations, you successfully deployed MLFlow on your project! 🎉"
	@source vars && echo "The web app is available at https://mlflow-dot-$${TF_VAR_project_id}.ew.r.appspot.com (You may have trouble connecting for a few minutes after the deployment, while IAP gets setup)"
	@echo "To push your first experiment, take a look at the bottom of the readme for an example."


#################
#   DEVTOOLS    #
#################

setup-new-project:
	rm -rf .terraform vars vars.json && cd IaC && rm -rf .terraform .terraform.lock.hcl prerequesites/.terraform prerequesites/.terraform.lock.hcl prerequesites/terraform.tfstate prerequesites/terraform.tfstate.backup
	gcloud auth login && gcloud auth application-default login
