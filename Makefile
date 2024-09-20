# Copyright 2023 VMware, Inc.
# SPDX-License-Identifier: MPL-2.0

SHELL := /usr/bin/env bash -o errexit -o pipefail -o nounset
MAKEFLAGS += -s
.DEFAULT_GOAL := help
.EXPORT_ALL_VARIABLES:

# Default variables
DEFAULT_ARTIFACTS_CONTAINER_PORT = 8081
DEFAULT_PACKER_HTTP_PORT = 8082
DEFAULT_IMAGE_BUILDER_BASE_IMAGE = vsphere-docker-virtual.usw5.packages.broadcom.com/photon:5.0
MAKE_HELPERS_PATH = $(shell pwd)/hack/make-helpers
DEFAULT_SUPPORTED_VERSIONS_JSON = $(shell pwd)/supported-versions.json

ifndef SUPPORTED_VERSIONS_JSON
override SUPPORTED_VERSIONS_JSON = $(DEFAULT_SUPPORTED_VERSIONS_JSON)
endif

# Terminal colors
clear=\033[0m
green=\033[0;32m

define LIST_VERSIONS_HELP_INFO
# To list supported Kubernetes versions and their corresponding supported OS targets
#
# Example:
#   make list-versions
endef
.PHONY: list-versions
ifeq ($(PRINT_HELP),y)
list-versions:
	printf "$$green$$LIST_VERSIONS_HELP_INFO$$clear\n"
else
list-versions:
	$(MAKE_HELPERS_PATH)/list-versions.sh
endif

define RUN_ARTIFACTS_CONTAINER_HELP_INFO
# Runs the artifacts container for a Kubernetes version. 
# 
# Arguments:
#   KUBERNETES_VERSION: [Required] kubernetes version of the artifacts containers, to see
#                       list of supported kubernetes versions use "make list-versions"
#   ARTIFACTS_CONTAINER_PORT: [Optional] container port, if not provided 
#                             defaults to $(DEFAULT_ARTIFACTS_CONTAINER_PORT)
# Example:
# make run-artifacts-container KUBERNETES_VERSION=v1.22.13+vmware.1
# make run-artifacts-container KUBERNETES_VERSION=v1.22.13+vmware.1 ARTIFACTS_CONTAINER_PORT=9090
endef
.PHONY: run-artifacts-container
ifeq ($(PRINT_HELP),y)
run-artifacts-container:
	printf "$$green$$RUN_ARTIFACTS_CONTAINER_HELP_INFO$$clear\n"
else
run-artifacts-container:
	$(MAKE_HELPERS_PATH)/run-artifacts-container.sh -p $(ARTIFACTS_CONTAINER_PORT) -k $(KUBERNETES_VERSION)
endif

define BUILD_IMAGE_BUILDER_CONTAINER_HELP_INFO
# Will create a docker container image for creation of TKGs OVA with the dependencies
# like packer, ansible and kubernetes image builder code.
# 
# Arguments:
#   KUBERNETES_VERSION: [Required] kubernetes version of the artifacts containers, to see
#                       list of supported kubernetes versions use "make list-versions".
# Example:
# make build-image-builder-container KUBERNETES_VERSION=v1.23.15+vmware.1
endef
.PHONY: build-image-builder-container
ifeq ($(PRINT_HELP),y)
build-image-builder-container:
	printf "$$green$$BUILD_IMAGE_BUILDER_CONTAINER_HELP_INFO$$clear\n"
else
build-image-builder-container:
	$(MAKE_HELPERS_PATH)/build-image-builder-container.sh
endif

define BUILD_NODE_IMAGE
# To build vSphere Tanzu Kubernetes Grid compliant node images
#
# Arguments:
#   OS_TARGET: [Required] Node Image OS target, to see list of supported OS target
#               use "make list-versions".
#   KUBERNETES_VERSION: [Required] kubernetes version of the artifacts containers, to see
#                       list of supported kubernetes versions use "make list-versions".
#   TKR_SUFFIX: [Required] TKR suffix for the generated Node image, this can be used to
#               distinguish different node images.
#   IMAGE_ARTIFACTS_PATH: [Required] Node image OVA and packer logs output folder.
#   HOST_IP: [Required] IP Address of host where artifact container is running.
#   ARTIFACTS_CONTAINER_PORT: [Optional] Artifacts container port, defaults to $(DEFAULT_ARTIFACTS_CONTAINER_PORT)
#   PACKER_HTTP_PORT: [Optional] Port used by Packer HTTP server for hosting the Preseed/Autoinstall files,
#                     defaults to $(DEFAULT_PACKER_HTTP_PORT).
# 
# Example:
# make build-node-image OS_TARGET=photon-3 KUBERNETES_VERSION=v1.23.15+vmware.1 TKR_SUFFIX=byoi HOST_IP=1.2.3.4 IMAGE_ARTIFACTS_PATH=$(HOME)/image
# make build-node-image OS_TARGET=photon-3 KUBERNETES_VERSION=v1.23.15+vmware.1 TKR_SUFFIX=byoi HOST_IP=1.2.3.4 IMAGE_ARTIFACTS_PATH=$(HOME)/image ARTIFACTS_CONTAINER_PORT=9090 PACKER_HTTP_PORT=9091
endef
.PHONY: build-node-image
ifeq ($(PRINT_HELP),y)
build-node-image:
	printf "$$green$$BUILD_NODE_IMAGE$$clear\n"
else
build-node-image: build-image-builder-container
	$(MAKE_HELPERS_PATH)/build-node-image.sh
endif

define CLEAN_CONTAINERS_HELP_IFO
# To Stops and remove BYOI related docker containers
#
# Arguments:
#   LABEL: [Optional] To delete containers selectively based on labels
#          When docker containers are created they are labeled with the below keys, both artifacts and
#          image builder container will have the "byoi" label key. Artifacts containers will have
#          "byoi_artifacts" and Kubernetes version label keys are added. Image builder containers
#          will have "byoi_image_builder", Kubernetes version, and OS target label keys are added
# Example:
# make clean-containers
# make clean-containers LABEL=byoi
# make clean-containers LABEL=byoi_artifacts
# make clean-containers LABEL=byoi_image_builder
# make clean-containers LABEL=v1.23.15+vmware.1
# make clean-containers LABEL=photon-3
endef
.PHONY: clean-containers
ifeq ($(PRINT_HELP),y)
clean-containers:
	printf "$$green$$CLEAN_CONTAINERS_HELP_IFO$$clear\n"
else
clean-containers:
	$(MAKE_HELPERS_PATH)/clean-containers.sh
endif

define CLEAN_IMAGE_ARTIFACTS_HELP_INFO
# To clean the artifacts generated by the image builder container
#
# Arguments:
#   IMAGE_ARTIFACTS_PATH: [Required] Node image OVA and packer logs output folder.
#
# Example:
# make clean-image-artifacts IMAGE_ARTIFACTS_PATH=$(HOME)/image-artifacts
endef
.PHONY: clean-image-artifacts
ifeq ($(PRINT_HELP),y)
clean-image-artifacts:
	printf "$$green$$CLEAN_IMAGE_ARTIFACTS_HELP_INFO$$clear\n"
else
clean-image-artifacts:
	$(MAKE_HELPERS_PATH)/clean-image-artifacts.sh
endif

define CLEAN_HELP_INFO
# To clean the artifacts and containers generated or created when building the image
#
# Arguments:
#   IMAGE_ARTIFACTS_PATH: [Required] Node image OVA and packer logs output folder.
#   LABEL: [Optional] To delete containers selectively based on labels
#          When docker containers are created they are labeled with the below keys, both artifacts and
#          image builder container will have the "byoi" label key. Artifacts containers will have
#          "byoi_artifacts" and Kubernetes version label keys are added. Image builder containers
#          will have "byoi_image_builder", Kubernetes version, and OS target label keys are added
#
# Example:
# make clean IMAGE_ARTIFACTS_PATH=$(HOME)/image-artifacts
# make clean IMAGE_ARTIFACTS_PATH=$(HOME)/image-artifacts LABEL=byoi
endef
.PHONY: clean
ifeq ($(PRINT_HELP),y)
clean:
	printf "$$green$$CLEAN_HELP_INFO$$clear\n"
else
clean: clean-containers clean-image-artifacts
endif

define HELP_INFO
# Use to list supported Kubernetes versions and the corresponding supported OS targets
#
# Example:
#   make
#   make help
endef
.PHONY: help
ifeq ($(PRINT_HELP),y)
help:
	printf "$$green$$HELP_INFO$$clear\n"
else
help: ## help
	$(MAKE_HELPERS_PATH)/make-help.sh
endif