.PHONY: setup format test tf-plan-dev

setup:
	python -m venv .venv
	. .venv/Scripts/activate && pip install -r app/lambda_transform/requirements.txt && pip install pytest black

format:
	. .venv/Scripts/activate && black app/lambda_transform app/data_generator

test:
	. .venv/Scripts/activate && pytest

tf-plan-dev:
	cd infra/terraform/envs/dev && terraform init && terraform plan

