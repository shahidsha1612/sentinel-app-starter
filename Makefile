# Sentinel starter — convenience targets.
# All AWS actions target a SANDBOX profile. Never use a real/prod account, and
# never store real CUI in this lab.

AWS_PROFILE ?= default
TF          := terraform -chdir=terraform
export AWS_PROFILE

.PHONY: help score advisory init deploy test destroy fmt

help:
	@echo "Sentinel starter targets:"
	@echo "  make score                 - run the deterministic self-evaluation"
	@echo "  make advisory              - score + run opa/terraform if installed (not graded)"
	@echo "  make deploy  AWS_PROFILE=x  - terraform init + apply into a sandbox"
	@echo "  make test    AWS_PROFILE=x  - upload + fetch a synthetic file"
	@echo "  make destroy AWS_PROFILE=x  - tear the sandbox down"

score:
	python3 scoring/score.py

advisory:
	python3 scoring/score.py --advisory

init:
	$(TF) init

deploy: init
	$(TF) apply -auto-approve

test:
	@API=$$($(TF) output -raw api_endpoint); \
	echo "Exercising $$API"; \
	API=$$API ./test/smoke.sh

destroy:
	$(TF) destroy -auto-approve

fmt:
	$(TF) fmt -recursive
