export APP_NAME = "$(shell basename $(shell pwd) | tr '[:upper:]' '[:lower:]')"
export IPADDR = $(shell ip addr show ens192 | grep -Po 'inet \K[\d.]+')
export CONTAINER_NAME := $(APP_NAME)_$(shell date +%s)
export USE_R_VERSION = "$(shell jq -r '.R.Version' renv.lock)"
export USE_RENV_VERSION = "$(shell jq -r '.Packages.renv.Version' renv.lock)"
SHINYPROXY_USERGROUPS = "ERS_USER"
export SHINYPROXY_CONFIG_YML="/etc/shinyproxy/application.yml"

# by default, use the test tag
# if you want to deploy to production, run `make deploy ERS_DEPLOY=prod`
ERS_DEPLOY ?= "dev"
export TAG = $(ERS_DEPLOY)
export APP_NAME_TAG = "$(APP_NAME):$(TAG)"

.PHONY: delete_image \
	build_image \
	run_container \
	renv_isolate \
	shinyproxy_users \
	commit_container \
	stop_container \
	run \
	run_as \
	tunnel_run \
	docker_bin_bash \
	generate_shinyproxy_config \
	clean \
	install

app_name:
	@echo $(ERS_DEPLOY)
	@echo $(APP_NAME)
	@echo $(APP_NAME_TAG)
	@echo $(IPADDR)
	@echo $(CONTAINER_NAME)
	@echo $(R_VERSION)
	@echo $(RENV_VERSION)

shinyproxy_users:
	@echo $(APP_NAME)
	grep --after-context 1 '\- name: gbs' $(SHINYPROXY_CONFIG_YML)

delete_image:
	@if docker image inspect $(APP_NAME_TAG) >/dev/null 2>&1; then \
		docker rmi -f $(APP_NAME_TAG); \
	else \
		echo "Skipped - Image does not exist."; \
	fi

build_image:
	docker build -t $(APP_NAME_TAG) -f Dockerfile .

run_container:
	docker run --name $(CONTAINER_NAME) -d -it --rm -v /home/public/.cache/R/renv:/renv/cache $(APP_NAME_TAG) /bin/bash

renv_isolate:
	docker exec $(CONTAINER_NAME) R -e "renv::restore('/home/ers_bot/shiny'); renv::isolate()"

commit_container:
	docker commit $(shell docker ps --all -lq --filter "ancestor=$(APP_NAME_TAG)") $(APP_NAME_TAG)

stop_container:
	docker stop $(CONTAINER_NAME)

run:
	docker run --rm -it $(APP_NAME_TAG) R -e "devtools::load_all(); app('app', launch.browser = FALSE)"

run_as:
	docker run -p 8089:3838 --name $(CONTAINER_NAME) -it --rm -e SHINYPROXY_USERGROUPS=$(SHINYPROXY_USERGROUPS) $(APP_NAME_TAG) R -e "devtools::load_all(); app('app', launch.browser = FALSE)"

tunnel_run:
	docker run -p 8089:3838 --rm -it $(APP_NAME_TAG) R -e "shiny::runApp('.', launch.browser = FALSE, host = '0.0.0.0', port = 3838)"

generate_shinyproxy_config:
	shinyproxy_config $(SHINYPROXY_CONFIG_YML)

docker_bin_bash:
	docker run --name $(CONTAINER_NAME) -it --rm -v /home/public/.cache/R/renv:/renv/cache $(APP_NAME_TAG) /bin/bash

clean: delete_image

install: delete_image build_image run_container renv_isolate commit_container stop_container

