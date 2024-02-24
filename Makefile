REGISTRY ?= ghcr.io
OWNER ?= mecha-ci
REPOSITORY ?= images

.PHONY: check-variable-% image-kind

check-variable-%:
	@[[ "${${*}}" ]] || (echo '*** Please define variable `${*}` ***' && exit 1)

image-kind: check-variable-IMAGE
	@find . -name "${IMAGE}" -type d | cut -d '/' -f -2

.PHONY: keygen melange apko docker-load clean clean-all build build-all run

keygen:
	@docker run --rm -v $${PWD}:/work -w /work cgr.dev/chainguard/melange:latest keygen

melange: check-variable-ARCH check-variable-IMAGE
	@export KIND=$$(find . -name "${IMAGE}" -type d | cut -d '/' -f -2) && \
	melange build --arch=${ARCH} --debug \
		--signing-key=melange.rsa \
		--out-dir=$${KIND}/${IMAGE}/packages \
		$${KIND}/${IMAGE}/melange.yaml

apko: check-variable-ARCH check-variable-IMAGE
	@export KIND=$$(find . -name "${IMAGE}" -type d | cut -d '/' -f -2) && \
	mkdir -p "$${KIND}/${IMAGE}/sboms" && \
	apko build --arch=${ARCH} --debug \
		--keyring-append=melange.rsa.pub \
		--sbom-path=$${KIND}/${IMAGE}/sboms \
		$${KIND}/${IMAGE}/apko.yaml "${REGISTRY}/${OWNER}/${REPOSITORY}:${IMAGE}-dev" $${KIND}/${IMAGE}/oci-image.tar

docker-load: check-variable-IMAGE
	@if [ -f tools/${IMAGE}/oci-image.tar ]; then docker load -i tools/${IMAGE}/oci-image.tar; fi
	@if [ -f collections/${IMAGE}/oci-image.tar ]; then docker load -i collections/${IMAGE}/oci-image.tar; fi

build: check-variable-IMAGE check-variable-ARCH clean melange apko docker-load

build-all: check-variable-ARCH
	find ./tools -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | xargs -I {} make build IMAGE={} ARCH=${ARCH}

run: build
	@docker run --rm -it "${REGISTRY}/${OWNER}/${REPOSITORY}:${IMAGE}-dev"

clean: check-variable-IMAGE
	@find . -path "*/${IMAGE}/*" -name "oci-image.tar" -type f -delete
	@find . -path "*/${IMAGE}/*" -name "packages" -type d -exec rm -rf {} +
	@find . -path "*/${IMAGE}/*" -name "reports" -type d -exec rm -rf {} +
	@find . -path "*/${IMAGE}/*" -name "sboms" -type d -exec rm -rf {} +

clean-all:
	@find . -name "oci-image.tar" -type f -delete
	@find . -name "packages" -type d -exec rm -rf {} +
	@find . -name "reports" -type d -exec rm -rf {} +
	@find . -name "sboms" -type d -exec rm -rf {} +

.PHONY: dockle grype trivy snyk scan dockle-all grype-all trivy-all snyk-all scan-all

dockle: check-variable-ARCH check-variable-IMAGE
	@export KIND=$$(find . -name "${IMAGE}" -type d | cut -d '/' -f -2) && \
	mkdir -p "$${KIND}/${IMAGE}/reports" && \
	dockle -f json -o "$${KIND}/${IMAGE}/reports/dockle.json" --debug "${REGISTRY}/${OWNER}/${REPOSITORY}:${IMAGE}-dev-${ARCH}"

dockle-all: check-variable-ARCH
	@find ./tools -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | xargs -I {} make dockle IMAGE={} ARCH=${ARCH}

grype: check-variable-ARCH check-variable-IMAGE
	@export KIND=$$(find . -name "${IMAGE}" -type d | cut -d '/' -f -2) && \
	mkdir -p "$${KIND}/${IMAGE}/reports" && \
	grype -o json --file "$${KIND}/${IMAGE}/reports/grype.json" "${REGISTRY}/${OWNER}/${REPOSITORY}:${IMAGE}-dev-${ARCH}" -vv

grype-all: check-variable-ARCH
	@find ./tools -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | xargs -I {} make grype IMAGE={} ARCH=${ARCH}

trivy: check-variable-ARCH check-variable-IMAGE
	@export KIND=$$(find . -name "${IMAGE}" -type d | cut -d '/' -f -2) && \
	mkdir -p "$${KIND}/${IMAGE}/reports" && \
	trivy image -d -f json -o "$${KIND}/${IMAGE}/reports/trivy.json" "${REGISTRY}/${OWNER}/${REPOSITORY}:${IMAGE}-dev-${ARCH}"

trivy-all: check-variable-ARCH
	@find ./tools -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | xargs -I {} make trivy IMAGE={} ARCH=${ARCH}

snyk: check-variable-ARCH check-variable-IMAGE check-variable-SNYK_ORG
	@export KIND=$$(find . -name "${IMAGE}" -type d | cut -d '/' -f -2) && \
	mkdir -p "$${KIND}/${IMAGE}/reports" && \
	snyk container test -d \
		--org=$${SNYK_ORG} "${REGISTRY}/${OWNER}/${REPOSITORY}:${IMAGE}-dev-${ARCH}" \
		--json-file-output="$${KIND}/${IMAGE}/reports/snyk.json"

snyk-all: check-variable-ARCH
	@find ./tools -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | xargs -I {} make snyk IMAGE={} ARCH=${ARCH}

scan: check-variable-ARCH check-variable-IMAGE dockle grype trivy snyk

scan-all: check-variable-ARCH
	find ./tools -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | xargs -I {} make scan IMAGE={} ARCH=${ARCH}
