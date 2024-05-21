VERSION         := 0.0.1

PACK            := xyz
PROJECT         := github.com/pulumi/pulumi-${PACK}

PROVIDER        := pulumi-resource-${PACK}
VERSION_PATH    := provider/pkg/version.Version

WORKING_DIR     := $(shell pwd)
SCHEMA_PATH     := ${WORKING_DIR}/schema.json

SRC             := provider/cmd/pulumi-resource-${PACK}

# The pulumi binary to use during generation
PULUMI := .pulumi/bin/pulumi

export PULUMI_IGNORE_AMBIENT_PLUGINS = true

generate:: gen_go_sdk gen_dotnet_sdk gen_nodejs_sdk gen_python_sdk
gen_sdk_prerequisites: $(PULUMI)

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
	cp ${WORKING_DIR}/schema.json ${SRC}/${PACK}_provider/schema.json
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

gen_go_sdk: gen_sdk_prerequisites
	rm -rf sdk/go
	$(PULUMI) package gen-sdk ${SCHEMA_PATH} --language go


# .NET SDK

gen_dotnet_sdk: DOTNET_VERSION := $(shell pulumictl get version --language dotnet)
gen_dotnet_sdk: gen_sdk_prerequisites
	rm -rf sdk/dotnet
	$(PULUMI) package gen-sdk ${SCHEMA_PATH} --language dotnet

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

gen_nodejs_sdk: VERSION := $(shell pulumictl get version --language javascript)
gen_nodejs_sdk: gen_sdk_prerequisites
	rm -rf sdk/nodejs
	$(PULUMI) package gen-sdk ${SCHEMA_PATH} --language nodejs

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

gen_python_sdk: PYPI_VERSION := $(shell pulumictl get version --language python)
gen_python_sdk: gen_sdk_prerequisites
	rm -rf sdk/python
	$(PULUMI) package gen-sdk ${SCHEMA_PATH} --language python
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


# Keep the version of the pulumi binary used for code generation in sync with the version
# of the dependency used by github.com/pulumi/pulumi-pulumiservice/provider

$(PULUMI): HOME := $(WORKING_DIR)
$(PULUMI): provider/go.mod
	@ PULUMI_VERSION="$$(cd provider && go list -m github.com/pulumi/pulumi/pkg/v3 | awk '{print $$2}')"; \
	if [ -x $(PULUMI) ]; then \
		CURRENT_VERSION="$$($(PULUMI) version)"; \
		if [ "$${CURRENT_VERSION}" != "$${PULUMI_VERSION}" ]; then \
			echo "Upgrading $(PULUMI) from $${CURRENT_VERSION} to $${PULUMI_VERSION}"; \
			rm $(PULUMI); \
		fi; \
	fi; \
	if ! [ -x $(PULUMI) ]; then \
		curl -fsSL https://get.pulumi.com | sh -s -- --version "$${PULUMI_VERSION#v}"; \
	fi