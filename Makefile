AWS_REGION=us-east-1
FUNCTION_DIR=lambda_lib
FUNCTION_NAME=lambda_function
LAMBDA_PACKAGE=lambda-package
VIRTUAL_ENV=lambda-virtualenv
TIMEOUT=236
LAMBDA_ROLE_PATH=arn:aws:iam::120409133518:role/copy_s3_files


install: venv requirements

build: clean_all venv requirements build_package_tmp copy_python remove_unused zip

clean_all:
	rm -rf $(VIRTUAL_ENV)
	rm -rf $(LAMBDA_PACKAGE)

clean_package:
	rm -rf ./$(LAMBDA_PACKAGE)/*

venv:
	if test ! -d "$(VIRTUAL_ENV)"; then \
		pip3 install virtualenv; \
		virtualenv $(VIRTUAL_ENV); \
	fi

requirements:
	pipenv lock -r > requirements.txt
	$(VIRTUAL_ENV)/bin/pip install -Ur requirements.txt

build_package_tmp:
	mkdir -p ./$(LAMBDA_PACKAGE)/tmp/
	cp -a ./$(FUNCTION_DIR)/. ./$(LAMBDA_PACKAGE)/tmp/

copy_python:
	@echo "==> Copying packages!"
	if test -d ./$(VIRTUAL_ENV)/lib; then \
		cp -a ./$(VIRTUAL_ENV)/lib/python3.6/site-packages/. ./$(LAMBDA_PACKAGE)/tmp/; \
	fi
	if test -d ./$(VIRTUAL_ENV)/lib64; then \
		cp -a ./$(VIRTUAL_ENV)/lib64/python3.6/site-packages/. ./$(LAMBDA_PACKAGE)/tmp/; \
	fi
	@echo ""

remove_unused:
	rm -rf ./$(LAMBDA_PACKAGE)/tmp/wheel*
	rm -rf ./$(LAMBDA_PACKAGE)/tmp/easy-install*
	rm -rf ./$(LAMBDA_PACKAGE)/tmp/setuptools*

zip:
	cd ./$(LAMBDA_PACKAGE)/tmp && zip -r ../$(FUNCTION_NAME).zip .

lambda_delete:
	aws lambda delete-function \
		--function-name $(FUNCTION_NAME)

lambda_create:
	aws lambda create-function \
		--region $(AWS_REGION) \
		--function-name $(FUNCTION_NAME) \
		--zip-file fileb://./$(LAMBDA_PACKAGE)/$(FUNCTION_NAME).zip \
		--role $(LAMBDA_ROLE_PATH) \
		--handler lambda_function.lambda_handler \
		--runtime python3.6 \
		--timeout $(TIMEOUT) \
		--memory-size 128

lambda_test:
	aws lambda invoke \
		--invocation-type DryRun \
		--function-name $(FUNCTION_NAME) \
		--payload '{}'\
		outfile

lambda_update:
	  aws lambda update-function-code \
		--function-name $(FUNCTION_NAME) \
		--zip-file fileb://./$(LAMBDA_PACKAGE)/$(FUNCTION_NAME).zip
