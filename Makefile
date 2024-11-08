REGISTRY ?= ghcr.io
OWNER ?= mecha-hq
REPOSITORY ?= images
PROJECT_DIR=$(dir $(abspath $(lastword $(MAKEFILE_LIST))))

.PHONY: check-variable-%
check-variable-%:
	@[ -n "$(${*})" ] || (echo '*** Please define variable `${*}` ***' && exit 1)

.PHONY: image-kind
image-kind: check-variable-IMAGE
	@find . -name "${IMAGE}" -type d | cut -d '/' -f -2

.PHONY: validate-name
validate-name: check-variable-IMAGE
	@${PROJECT_DIR}/scripts/validate-name.sh ${IMAGE}

.PHONY: validate-arch
validate-arch: check-variable-ARCH
	@${PROJECT_DIR}/scripts/validate-arch.sh ${ARCH}

.PHONY: tool-version
tool-version: check-variable-IMAGE
	@grep 'version' tools/${IMAGE}/melange.yaml | head -n 1 | sed 's/.*version: *//'

.PHONY: keygen
keygen:
	@docker run --rm -v $${PWD}:/work -w /work cgr.dev/chainguard/melange:latest keygen

.PHONY: melange
melange: check-variable-ARCH check-variable-IMAGE
	@export KIND=$$(find . -name "${IMAGE}" -type d | cut -d '/' -f -2) && \
	melange build --arch=${ARCH} --debug \
		--signing-key=melange.rsa \
		--out-dir=$${KIND}/${IMAGE}/packages \
		$${KIND}/${IMAGE}/melange.yaml

.PHONY: apko
apko: check-variable-ARCH check-variable-IMAGE check-variable-VERSION
	@export KIND=$$(find . -name "${IMAGE}" -type d | cut -d '/' -f -2) && \
	mkdir -p "$${KIND}/${IMAGE}/sboms" && \
	apko build --arch=${ARCH} --log-level=debug \
		--build-date=$$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
		--keyring-append=melange.rsa.pub \
		--sbom-path=$${KIND}/${IMAGE}/sboms \
		$${KIND}/${IMAGE}/apko.yaml "${REGISTRY}/${OWNER}/${IMAGE}:${VERSION}" $${KIND}/${IMAGE}/oci-image-${VERSION}.tar

.PHONY: docker-load
docker-load: check-variable-IMAGE check-variable-VERSION
	@if [ -f tools/${IMAGE}/oci-image-${VERSION}.tar ]; then docker load -i tools/${IMAGE}/oci-image-${VERSION}.tar; fi
	@if [ -f collections/${IMAGE}/oci-image-${VERSION}.tar ]; then docker load -i collections/${IMAGE}/oci-image-${VERSION}.tar; fi

.PHONY: build
build: clean melange apko docker-load

.PHONY: build-all
build-all: check-variable-ARCH
	find ./tools -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | xargs -I {} make build IMAGE={} ARCH=${ARCH}

.PHONY: run
run: check-variable-ARCH check-variable-IMAGE check-variable-VERSION build
	@docker run --rm -it "${REGISTRY}/${OWNER}/${IMAGE}:${VERSION}-${ARCH}"

.PHONY: docker-push
docker-push: check-variable-ARCH check-variable-IMAGE check-variable-VERSION
	@for a in $$(echo "${ARCH}" | sed "s/,/ /g"); do \
		docker push "${REGISTRY}/${OWNER}/${IMAGE}:${VERSION}-$$a"; \
	done

.PHONY: docker-manifest
docker-manifest: check-variable-ARCH check-variable-IMAGE check-variable-VERSION
	@${PROJECT_DIR}/scripts/docker-manifest.sh "${REGISTRY}" "${OWNER}" "${IMAGE}" "${VERSION}" "${ARCH}"

.PHONY: clean
clean: check-variable-IMAGE
	@find . -path "*/${IMAGE}/*" -name "oci-image-*.tar" -type f -delete
	@find . -path "*/${IMAGE}/*" -name "packages" -type d -exec rm -rf {} +
	@find . -path "*/${IMAGE}/*" -name "reports" -type d -exec rm -rf {} +
	@find . -path "*/${IMAGE}/*" -name "sboms" -type d -exec rm -rf {} +

.PHONY: clean-all
clean-all:
	@find . -name "oci-image-*.tar" -type f -delete
	@find . -name "packages" -type d -exec rm -rf {} +
	@find . -name "reports" -type d -exec rm -rf {} +
	@find . -name "sboms" -type d -exec rm -rf {} +

.PHONY: dockle
dockle: check-variable-ARCH check-variable-IMAGE check-variable-VERSION
	@export KIND=$$(find . -name "${IMAGE}" -type d | cut -d '/' -f -2) && \
	mkdir -p "$${KIND}/${IMAGE}/reports" && \
	dockle -f json -o "$${KIND}/${IMAGE}/reports/dockle-${VERSION}-${ARCH}.json" --debug "${REGISTRY}/${OWNER}/${IMAGE}:${VERSION}-${ARCH}"

.PHONY: dockle-all
dockle-all: check-variable-ARCH
	@find ./tools -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | xargs -I {} make dockle IMAGE={} ARCH=${ARCH}

.PHONY: grype
grype: check-variable-ARCH check-variable-IMAGE check-variable-VERSION
	@export KIND=$$(find . -name "${IMAGE}" -type d | cut -d '/' -f -2) && \
	mkdir -p "$${KIND}/${IMAGE}/reports" && \
	grype -o json --file "$${KIND}/${IMAGE}/reports/grype-${VERSION}-${ARCH}.json" "${REGISTRY}/${OWNER}/${IMAGE}:${VERSION}-${ARCH}" -vv

.PHONY: grype-all
grype-all: check-variable-ARCH
	@find ./tools -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | xargs -I {} make grype IMAGE={} ARCH=${ARCH}

.PHONY: trivy
trivy: check-variable-ARCH check-variable-IMAGE check-variable-VERSION
	@export KIND=$$(find . -name "${IMAGE}" -type d | cut -d '/' -f -2) && \
	mkdir -p "$${KIND}/${IMAGE}/reports" && \
	trivy image -d -f json -o "$${KIND}/${IMAGE}/reports/trivy-${VERSION}-${ARCH}.json" "${REGISTRY}/${OWNER}/${IMAGE}:${VERSION}-${ARCH}"

.PHONY: trivy-all
trivy-all: check-variable-ARCH
	@find ./tools -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | xargs -I {} make trivy IMAGE={} ARCH=${ARCH}

.PHONY: snyk
snyk: check-variable-ARCH check-variable-IMAGE check-variable-VERSION
	@export KIND=$$(find . -name "${IMAGE}" -type d | cut -d '/' -f -2) && \
	mkdir -p "$${KIND}/${IMAGE}/reports" && \
	snyk container test -d \
		--org=$${SNYK_ORG} "${REGISTRY}/${OWNER}/${IMAGE}:${VERSION}-${ARCH}" \
		--json-file-output="$${KIND}/${IMAGE}/reports/snyk-${VERSION}-${ARCH}.json"

.PHONY: snyk-all
snyk-all: check-variable-ARCH
	@find ./tools -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | xargs -I {} make snyk IMAGE={} ARCH=${ARCH}

.PHONY: scan
scan: dockle grype trivy snyk

.PHONY: scan-all
scan-all: check-variable-ARCH
	find ./tools -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | xargs -I {} make scan IMAGE={} ARCH=${ARCH}

.PHONY: folders
folders: check-variable-IMAGE
	@export KIND=$$(find . -name "${IMAGE}" -type d | cut -d '/' -f -2) && \
	mkdir -p dist/${IMAGE}/renders && \
	cp -R $${KIND}/${IMAGE}/reports dist/${IMAGE}/reports

.PHONY: render
render: folders render-dockle render-grype render-trivy render-snyk

.PHONY: render-dockle
render-dockle: check-variable-ARCH check-variable-IMAGE check-variable-VERSION
	@export KIND=$$(find . -name "${IMAGE}" -type d | cut -d '/' -f -2) && \
	ekdo render dockle \
		--output-dir=dist/${IMAGE}/renders \
		$${KIND}/${IMAGE}/reports/dockle-${VERSION}-${ARCH}.json

.PHONY: render-grype
render-grype: check-variable-ARCH check-variable-IMAGE check-variable-VERSION
	@export KIND=$$(find . -name "${IMAGE}" -type d | cut -d '/' -f -2) && \
	ekdo render grype \
		--output-dir=dist/${IMAGE}/renders \
		$${KIND}/${IMAGE}/reports/grype-${VERSION}-${ARCH}.json

.PHONY: render-trivy
render-trivy: check-variable-ARCH check-variable-IMAGE check-variable-VERSION
	@export KIND=$$(find . -name "${IMAGE}" -type d | cut -d '/' -f -2) && \
	ekdo render trivy \
		--output-dir=dist/${IMAGE}/renders \
		$${KIND}/${IMAGE}/reports/trivy-${VERSION}-${ARCH}.json

.PHONY: render-snyk
render-snyk: check-variable-ARCH check-variable-IMAGE check-variable-VERSION
	@export KIND=$$(find . -name "${IMAGE}" -type d | cut -d '/' -f -2) && \
	ekdo render snyk \
		--output-dir=dist/${IMAGE}/renders \
		$${KIND}/${IMAGE}/reports/snyk-${VERSION}-${ARCH}.json
