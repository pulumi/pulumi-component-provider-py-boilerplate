VERSION         := 0.0.1

PACK            := xyz
PROJECT         := github.com/pulumi/pulumi-${PACK}

PROVIDER        := pulumi-resource-${PACK}
CODEGEN         := pulumi-gen-${PACK}
VERSION_PATH    := provider/pkg/version.Version

WORKING_DIR     := $(shell pwd)
SCHEMA_PATH     := ${WORKING_DIR}/schema.json

SRC             := provider/cmd/pulumi-resource-${PACK}

generate:: gen_go_sdk gen_dotnet_sdk gen_nodejs_sdk gen_python_sdk

build:: build_provider build_dotnet_sdk build_nodejs_sdk build_python_sdk
install:: install_dotnet_sdk install_nodejs_sdk


# Provider

PROVIDER_FILES =  bin/PulumiPlugin.yaml bin/requirements.txt bin/run-provider.py
PROVIDER_FILES += bin/pulumi-resource-${PACK}.cmd bin/pulumi-resource-${PACK}

build_provider::	bin/venv bin/${PACK}_provider ${PROVIDER_FILES}

bin/venv:		${SRC}/requirements.txt
	rm -rf $@
	python3 -m venv $@
	./bin/venv/bin/python -m pip install -r $<

bin/${PACK}_provider:	${SRC}/	${SRC}/${PACK}_provider/VERSION
	rm -rf $@
	./bin/venv/bin/python -m pip install --no-deps provider/cmd/pulumi-resource-${PACK}/ -t bin/

bin/PulumiPlugin.yaml:			${SRC}/PulumiPlugin.yaml
bin/requirements.txt:			${SRC}/requirements.txt
bin/pulumi-resource-${PACK}.cmd:	${SRC}/pulumi-resource-${PACK}.cmd
bin/pulumi-resource-${PACK}:		${SRC}/pulumi-resource-${PACK}
bin/run-provider.py:			${SRC}/run-provider.py

bin/%:
	cp -f $< $@

${SRC}/${PACK}_provider/VERSION:
	echo "${VERSION}" > ${SRC}/${PACK}_provider/VERSION

# Go SDK

gen_go_sdk::
	rm -rf sdk/go
	cd provider/cmd/${CODEGEN} && go run . go ../../../sdk/go ${SCHEMA_PATH}


# .NET SDK

gen_dotnet_sdk::
	rm -rf sdk/dotnet
	cd provider/cmd/${CODEGEN} && go run . dotnet ../../../sdk/dotnet ${SCHEMA_PATH}

build_dotnet_sdk:: DOTNET_VERSION := ${VERSION}
build_dotnet_sdk:: gen_dotnet_sdk
	cd sdk/dotnet/ && \
		echo "${DOTNET_VERSION}" >version.txt && \
		dotnet build /p:Version=${DOTNET_VERSION}

install_dotnet_sdk:: build_dotnet_sdk
	rm -rf ${WORKING_DIR}/nuget
	mkdir -p ${WORKING_DIR}/nuget
	find . -name '*.nupkg' -print -exec cp -p {} ${WORKING_DIR}/nuget \;


# Node.js SDK

gen_nodejs_sdk::
	rm -rf sdk/nodejs
	cd provider/cmd/${CODEGEN} && go run . nodejs ../../../sdk/nodejs ${SCHEMA_PATH}

build_nodejs_sdk:: gen_nodejs_sdk
	cd sdk/nodejs/ && \
		yarn install && \
		yarn run tsc --version && \
		yarn run tsc && \
		cp ../../README.md ../../LICENSE package.json yarn.lock ./bin/ && \
		sed -i.bak -e "s/\$${VERSION}/$(VERSION)/g" ./bin/package.json && \
		rm ./bin/package.json.bak

install_nodejs_sdk:: build_nodejs_sdk
	yarn link --cwd ${WORKING_DIR}/sdk/nodejs/bin


# Python SDK

gen_python_sdk::
	rm -rf sdk/python
	cd provider/cmd/${CODEGEN} && go run . python ../../../sdk/python ${SCHEMA_PATH}
	cp ${WORKING_DIR}/README.md sdk/python

build_python_sdk:: PYPI_VERSION := ${VERSION}
build_python_sdk:: gen_python_sdk
	cd sdk/python/ && \
		python3 setup.py clean --all 2>/dev/null && \
		rm -rf ./bin/ ../python.bin/ && cp -R . ../python.bin && mv ../python.bin ./bin && \
		sed -i.bak -e "s/\$${VERSION}/${PYPI_VERSION}/g" -e "s/\$${PLUGIN_VERSION}/${VERSION}/g" ./bin/setup.py && \
		rm ./bin/setup.py.bak && \
		cd ./bin && python3 setup.py build sdist


# Output tarballs for plugin distribution. Example use:
#
# pulumi plugin install resource xyz 0.0.1 --file pulumi-resource-xyz-v0.0.1-linux-amd64.tar.gz

dist::	build_provider
	rm -rf dist
	mkdir -p dist
	(cd bin && tar --gzip --exclude venv --exclude pulumi-resource-${PACK}.cmd -cf ../dist/pulumi-resource-${PACK}-v${VERSION}-linux-amd64.tar.gz .)
	cp dist/pulumi-resource-${PACK}-v${VERSION}-linux-amd64.tar.gz dist/pulumi-resource-${PACK}-v${VERSION}-darwin-amd64.tar.gz
	cp dist/pulumi-resource-${PACK}-v${VERSION}-linux-amd64.tar.gz dist/pulumi-resource-${PACK}-v${VERSION}-darwin-arm64.tar.gz
	(cd bin && tar --gzip --exclude venv --exclude pulumi-resource-${PACK} -cf ../dist/pulumi-resource-${PACK}-v${VERSION}-windows-amd64.tar.gz .)
