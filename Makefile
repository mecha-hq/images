REGISTRY ?= ghcr.io
OWNER ?= mecha-hq
REPOSITORY ?= images

.PHONY: check-variable-%
check-variable-%:
	@[ -n "$(${*})" ] || (echo '*** Please define variable `${*}` ***' && exit 1)

.PHONY: image-kind
image-kind: check-variable-IMAGE
	@find . -name "${IMAGE}" -type d | cut -d '/' -f -2

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
apko: check-variable-ARCH check-variable-IMAGE
	@export KIND=$$(find . -name "${IMAGE}" -type d | cut -d '/' -f -2) && \
	mkdir -p "$${KIND}/${IMAGE}/sboms" && \
	apko build --arch=${ARCH} --log-level=debug \
		--keyring-append=melange.rsa.pub \
		--sbom-path=$${KIND}/${IMAGE}/sboms \
		$${KIND}/${IMAGE}/apko.yaml "${REGISTRY}/${OWNER}/${IMAGE}:dev" $${KIND}/${IMAGE}/oci-image.tar

.PHONY: docker-load
docker-load: check-variable-IMAGE
	@if [ -f tools/${IMAGE}/oci-image.tar ]; then docker load -i tools/${IMAGE}/oci-image.tar; fi
	@if [ -f collections/${IMAGE}/oci-image.tar ]; then docker load -i collections/${IMAGE}/oci-image.tar; fi

.PHONY: build
build: check-variable-IMAGE check-variable-ARCH clean melange apko docker-load

.PHONY: build-all
build-all: check-variable-ARCH
	find ./tools -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | xargs -I {} make build IMAGE={} ARCH=${ARCH}

.PHONY: run
run: build
	@docker run --rm -it "${REGISTRY}/${OWNER}/${IMAGE}:dev-${ARCH}"

.PHONY: docker-push
docker-push: check-variable-IMAGE check-variable-VERSION check-variable-ARCH
	@for a in $$(echo "${ARCH}" | sed "s/,/ /g"); do \
		docker push "${REGISTRY}/${OWNER}/${IMAGE}:${VERSION}-$$a"; \
	done

.PHONY: docker-manifest
docker-manifest: check-variable-IMAGE check-variable-VERSION check-variable-ARCH
	@docker manifest create \
		"${REGISTRY}/${OWNER}/${IMAGE}:${VERSION}" \
		$(foreach a, $(subst ,, ,$(ARCH)),--amend "${REGISTRY}/${OWNER}/${IMAGE}:${VERSION}-$a")
	@for a in $$(echo "${ARCH}" | sed "s/,/ /g"); do \
		@docker manifest annotate --arch $$a --os linux \
			"${REGISTRY}/${OWNER}/${IMAGE}:${VERSION}" \
			"${REGISTRY}/${OWNER}/${IMAGE}:${VERSION}-$$a"; \
	done
	@docker manifest push "${REGISTRY}/${OWNER}/${IMAGE}:${VERSION}"

.PHONY: clean
clean: check-variable-IMAGE
	@find . -path "*/${IMAGE}/*" -name "oci-image.tar" -type f -delete
	@find . -path "*/${IMAGE}/*" -name "packages" -type d -exec rm -rf {} +
	@find . -path "*/${IMAGE}/*" -name "reports" -type d -exec rm -rf {} +
	@find . -path "*/${IMAGE}/*" -name "sboms" -type d -exec rm -rf {} +

.PHONY: clean-all
clean-all:
	@find . -name "oci-image.tar" -type f -delete
	@find . -name "packages" -type d -exec rm -rf {} +
	@find . -name "reports" -type d -exec rm -rf {} +
	@find . -name "sboms" -type d -exec rm -rf {} +

.PHONY: dockle
dockle: check-variable-ARCH check-variable-IMAGE
	@export KIND=$$(find . -name "${IMAGE}" -type d | cut -d '/' -f -2) && \
	mkdir -p "$${KIND}/${IMAGE}/reports" && \
	dockle -f json -o "$${KIND}/${IMAGE}/reports/dockle.json" --debug "${REGISTRY}/${OWNER}/${IMAGE}:dev-${ARCH}"

.PHONY: dockle-all
dockle-all: check-variable-ARCH
	@find ./tools -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | xargs -I {} make dockle IMAGE={} ARCH=${ARCH}

.PHONY: grype
grype: check-variable-ARCH check-variable-IMAGE
	@export KIND=$$(find . -name "${IMAGE}" -type d | cut -d '/' -f -2) && \
	mkdir -p "$${KIND}/${IMAGE}/reports" && \
	grype -o json --file "$${KIND}/${IMAGE}/reports/grype.json" "${REGISTRY}/${OWNER}/${IMAGE}:dev-${ARCH}" -vv

.PHONY: grype-all
grype-all: check-variable-ARCH
	@find ./tools -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | xargs -I {} make grype IMAGE={} ARCH=${ARCH}

.PHONY: trivy
trivy: check-variable-ARCH check-variable-IMAGE
	@export KIND=$$(find . -name "${IMAGE}" -type d | cut -d '/' -f -2) && \
	mkdir -p "$${KIND}/${IMAGE}/reports" && \
	trivy image -d -f json -o "$${KIND}/${IMAGE}/reports/trivy.json" "${REGISTRY}/${OWNER}/${IMAGE}:dev-${ARCH}"

.PHONY: trivy-all
trivy-all: check-variable-ARCH
	@find ./tools -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | xargs -I {} make trivy IMAGE={} ARCH=${ARCH}

.PHONY: snyk
snyk: check-variable-ARCH check-variable-IMAGE check-variable-SNYK_ORG
	@export KIND=$$(find . -name "${IMAGE}" -type d | cut -d '/' -f -2) && \
	mkdir -p "$${KIND}/${IMAGE}/reports" && \
	snyk container test -d \
		--org=$${SNYK_ORG} "${REGISTRY}/${OWNER}/${IMAGE}:dev-${ARCH}" \
		--json-file-output="$${KIND}/${IMAGE}/reports/snyk.json"

.PHONY: snyk-all
snyk-all: check-variable-ARCH
	@find ./tools -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | xargs -I {} make snyk IMAGE={} ARCH=${ARCH}

.PHONY: scan
scan: check-variable-ARCH check-variable-IMAGE dockle grype trivy snyk

.PHONY: scan-all
scan-all: check-variable-ARCH
	find ./tools -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | xargs -I {} make scan IMAGE={} ARCH=${ARCH}

.PHONY: folders
folders: check-variable-IMAGE
	@mkdir -p dist/$$(sed 's/\:/--/g' <<< $${IMAGE})/renders
	@mkdir -p dist/$$(sed 's/\:/--/g' <<< $${IMAGE})/reports

.PHONY: render
render: check-variable-IMAGE folders render-dockle render-grype render-trivy render-snyk

.PHONY: render-dockle
render-dockle: check-variable-IMAGE
	@ekdo render dockle \
		--output-dir=dist/$$(sed 's/\:/--/g' <<< $${IMAGE})/renders \
		dist/$$(sed 's/\:/--/g' <<< $${IMAGE})/reports/dockle.json

.PHONY: render-grype
render-grype: check-variable-IMAGE
	@ekdo render grype \
		--output-dir=dist/$$(sed 's/\:/--/g' <<< $${IMAGE})/renders \
		dist/$$(sed 's/\:/--/g' <<< $${IMAGE})/reports/grype.json

.PHONY: render-trivy
render-trivy: check-variable-IMAGE
	@ekdo render trivy \
		--output-dir=dist/$$(sed 's/\:/--/g' <<< $${IMAGE})/renders \
		dist/$$(sed 's/\:/--/g' <<< $${IMAGE})/reports/trivy.json

.PHONY: render-snyk
render-snyk: check-variable-IMAGE
	@ekdo render snyk \
		--output-dir=dist/$$(sed 's/\:/--/g' <<< $${IMAGE})/renders \
		dist/$$(sed 's/\:/--/g' <<< $${IMAGE})/reports/snyk.json
