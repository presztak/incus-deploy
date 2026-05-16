# Deploy or destroy selected clusters. Clusters are defined in
# terraform/variables.tf (`clusters`) and ansible/hosts.yaml (one group each).
# See examples/multi-cluster.md.
#
#   make deploy                              # cluster1
#   make deploy CLUSTERS=cluster2
#   make deploy CLUSTERS="cluster1 cluster2"
#   make destroy CLUSTERS=cluster2           # only cluster2, shared project/network stay

CLUSTERS ?= cluster1

TOFU    ?= tofu
TF_DIR  := terraform
ANS_DIR := ansible

empty :=
space := $(empty) $(empty)
comma := ,

TARGETS := $(foreach c,$(CLUSTERS),-target='module.baremetal["$(c)"]')
LIMIT   := $(subst $(space),$(comma),$(strip $(CLUSTERS)))

.PHONY: deploy plan infra configure destroy

deploy: infra configure

plan:
	cd $(TF_DIR) && $(TOFU) init -input=false >/dev/null && $(TOFU) plan $(TARGETS)

infra:
	cd $(TF_DIR) && $(TOFU) init -input=false >/dev/null && $(TOFU) apply $(TARGETS)

configure:
	cd $(ANS_DIR) && ansible $(LIMIT) -m ansible.builtin.wait_for_connection -a timeout=300
	cd $(ANS_DIR) && ansible-playbook deploy.yaml --limit $(LIMIT)

destroy:
	cd $(TF_DIR) && $(TOFU) destroy $(TARGETS)
