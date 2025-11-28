# Use AWS Lambda python base image
FROM public.ecr.aws/lambda/python:3.10

# Copy function code
COPY src/ ${LAMBDA_TASK_ROOT}/

# Copy requirements and install
COPY requirements.txt  .
RUN pip install -r requirements.txt --target "${LAMBDA_TASK_ROOT}"

# Set the handler
CMD ["handler.lambda_handler"]
