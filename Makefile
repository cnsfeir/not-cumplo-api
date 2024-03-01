include .env
export

.PHONY: \
  publish \
  login

# Publishes the new configuration to the API Gateway
publish:
	@echo "\n\n🔨 Building the new configuration"
	$(eval NEW_CONFIGURATION_ID=$(shell echo "$(CONFIGURATION_ID)-$(shell date +"%Y%m%d%H%M%S")"))
	@gcloud api-gateway api-configs create $(NEW_CONFIGURATION_ID) --api=$(API_ID) --openapi-spec="$(CONFIGURATION_ID).yml" --project=$(PROJECT_ID) --backend-auth-service-account=$(SERVICE_ACCOUNT)

	@echo "\n\n🔄 Updating the API Gateway"
	$(eval ACTIVE_CONFIGURATION_ID=$(shell gcloud api-gateway gateways describe $(GATEWAY_ID) --location=$(LOCATION) --project=$(PROJECT_ID) --format="value(apiConfig)" | rev | cut -d'/' -f1 | rev))
	@gcloud api-gateway gateways update $(GATEWAY_ID) --api-config=$(NEW_CONFIGURATION_ID) --api=$(API_ID) --location=$(LOCATION) --project=$(PROJECT_ID)

	@echo "\n\n🔥 Deleting the old configurations"
	@$(eval CONFIGURATIONS := $(shell gcloud api-gateway api-configs list --api=cumplo-api --project=cumplo-scraper --format="value(CONFIG_ID,CREATE_TIME)" | sort -rk2 | tail -n +3 | cut -d' ' -f1))
	@$(foreach CONFIGURATION,$(CONFIGURATIONS),gcloud api-gateway api-configs delete $(CONFIGURATION) --api=$(API_ID) --project=$(PROJECT_ID) --quiet)

	@echo "\n\n✅ Done! \n"

login:
	@gcloud config configurations activate $(PROJECT_ID)
	@gcloud auth application-default login
