LAMBDA_DIR=app/lambda_transform
LAMBDA_DIST=$(LAMBDA_DIR)/dist
LAMBDA_IMAGE=aws-data-pipeline-lambda-transform


.PHONY: setup format test tf-plan-dev build-lambda

setup:
	python -m venv .venv
	. .venv/Scripts/activate && pip install -r app/lambda_transform/requirements.txt && pip install pytest black

format:
	. .venv/Scripts/activate && black app/lambda_transform app/data_generator

test:
	. .venv/Scripts/activate && pytest

tf-plan-dev:
	cd infra/terraform/envs/dev && terraform init && terraform plan

build-lambda:
	# Build Docker image with Lambda code + deps in /var/task
	docker build -t $(LAMBDA_IMAGE) $(LAMBDA_DIR)
	# Ensure dist directory exists (Windows-safe)
	powershell -Command "New-Item -ItemType Directory -Force -Path '$(LAMBDA_DIST)' | Out-Null"
	# Run container with /bin/sh as entrypoint and zip /var/task into dist/lambda.zip
	docker run --rm \
	  --entrypoint /bin/sh \
	  -v $(CURDIR)/$(LAMBDA_DIST):/out \
	  $(LAMBDA_IMAGE) \
	  -c "cd $${LAMBDA_TASK_ROOT:-/var/task} && zip -r /out/lambda.zip ."






