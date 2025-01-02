REGISTRY ?= ghcr.io
OWNER ?= mecha-hq
REPOSITORY ?= images
PROJECT_DIR=$(dir $(abspath $(lastword $(MAKEFILE_LIST))))

.PHONY: check-variable-%
check-variable-%:
	@[ -n "$(${*})" ] || (echo '*** Please define variable `${*}` ***' && exit 1)

.PHONY: image-kind
image-kind: check-variable-IMAGE
	@find . -maxdepth 2 -name "${IMAGE}" -type d | grep -E 'tools|collections' | cut -d '/' -f 2

.PHONY: validate-name
validate-name: check-variable-IMAGE
	@${PROJECT_DIR}/scripts/validate-name.sh ${IMAGE}

.PHONY: validate-arch
validate-arch: check-variable-ARCH
	@${PROJECT_DIR}/scripts/validate-arch.sh ${ARCH}

.PHONY: image-version
image-version: check-variable-IMAGE
	@grep 'version' tools/${IMAGE}/melange.yaml | head -n 1 | sed 's/.*version: *//' | sed 's/"//g'

.PHONY: keygen
keygen:
	@docker run --rm -v $${PWD}:/work -w /work cgr.dev/chainguard/melange:latest keygen

.PHONY: melange
melange: check-variable-ARCH check-variable-IMAGE
	export KIND=$(shell $(MAKE) image-kind IMAGE=${IMAGE}) && \
	export VERSION=$(shell $(MAKE) image-version IMAGE=${IMAGE}) && \
	melange build --arch=${ARCH} --debug \
		--signing-key=melange.rsa \
		--out-dir=dist/$${KIND}/${IMAGE}/$${VERSION}/packages \
		--runner=docker \
		$${KIND}/${IMAGE}/melange.yaml

.PHONY: apko
apko: check-variable-ARCH check-variable-IMAGE
	export KIND=$(shell $(MAKE) image-kind IMAGE=${IMAGE}) && \
	export VERSION=$(shell $(MAKE) image-version IMAGE=${IMAGE}) && \
	mkdir -p "dist/$${KIND}/${IMAGE}/$${VERSION}/images" && \
	mkdir -p "dist/$${KIND}/${IMAGE}/$${VERSION}/sboms" && \
	apko build --arch=${ARCH} --log-level=debug \
		--build-date=$$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
		--keyring-append=melange.rsa.pub \
		--sbom-path=dist/$${KIND}/${IMAGE}/$${VERSION}/sboms \
		$${KIND}/${IMAGE}/apko.yaml "${REGISTRY}/${OWNER}/${IMAGE}:$${VERSION}" \
		dist/$${KIND}/${IMAGE}/$${VERSION}/images/${IMAGE}-$${VERSION}.tar

.PHONY: docker-load
docker-load: check-variable-IMAGE check-variable-VERSION
	export KIND=$(shell $(MAKE) image-kind IMAGE=${IMAGE}) && \
	docker load -i dist/$${KIND}/${IMAGE}/${VERSION}/images/${IMAGE}-${VERSION}.tar

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
	@find . -name "dist/*/${IMAGE}" -type d -exec rm -rf {} +

.PHONY: clean-all
clean-all:
	@find . -name "dist" -type d -exec rm -rf {} +

.PHONY: dockle
dockle: check-variable-ARCH check-variable-IMAGE check-variable-VERSION
	@export KIND=$(shell $(MAKE) image-kind IMAGE=${IMAGE}) && \
	for a in $$(echo "${ARCH}" | sed "s/,/ /g"); do \
		mkdir -p "dist/$${KIND}/${IMAGE}/${VERSION}/reports/$${a}" && \
		dockle -f json -o "dist/$${KIND}/${IMAGE}/${VERSION}/reports/$${a}/dockle.json" --debug "${REGISTRY}/${OWNER}/${IMAGE}:${VERSION}-$${a}"; \
	done

.PHONY: dockle-all
dockle-all: check-variable-ARCH
	@find ./tools -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | xargs -I {} make dockle IMAGE={} ARCH=${ARCH}

.PHONY: grype
grype: check-variable-ARCH check-variable-IMAGE check-variable-VERSION
	@export KIND=$(shell $(MAKE) image-kind IMAGE=${IMAGE}) && \
	for a in $$(echo "${ARCH}" | sed "s/,/ /g"); do \
		mkdir -p "dist/$${KIND}/${IMAGE}/${VERSION}/reports/$${a}" && \
		grype -o json --file "dist/$${KIND}/${IMAGE}/${VERSION}/reports/$${a}/grype.json" "${REGISTRY}/${OWNER}/${IMAGE}:${VERSION}-$${a}" -vv; \
	done

.PHONY: grype-all
grype-all: check-variable-ARCH
	@find ./tools -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | xargs -I {} make grype IMAGE={} ARCH=${ARCH}

.PHONY: trivy
trivy: check-variable-ARCH check-variable-IMAGE check-variable-VERSION
	@export KIND=$(shell $(MAKE) image-kind IMAGE=${IMAGE}) && \
	for a in $$(echo "${ARCH}" | sed "s/,/ /g"); do \
		mkdir -p "dist/$${KIND}/${IMAGE}/${VERSION}/reports/$${a}" && \
		trivy image -d -f json -o dist/$${KIND}/${IMAGE}/${VERSION}/reports/$${a}/trivy.json" "${REGISTRY}/${OWNER}/${IMAGE}:${VERSION}-$${a}"; \
	done

.PHONY: trivy-all
trivy-all: check-variable-ARCH
	@find ./tools -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | xargs -I {} make trivy IMAGE={} ARCH=${ARCH}

.PHONY: snyk
snyk: check-variable-ARCH check-variable-IMAGE check-variable-VERSION
	@export KIND=$(shell $(MAKE) image-kind IMAGE=${IMAGE}) && \
	for a in $$(echo "${ARCH}" | sed "s/,/ /g"); do \
		mkdir -p "dist/$${KIND}/${IMAGE}/${VERSION}/reports/$${a}" && \
		snyk container test -d \
			--org=$${SNYK_ORG} "${REGISTRY}/${OWNER}/${IMAGE}:${VERSION}-$${a}" \
			--json-file-output="dist/$${KIND}/${IMAGE}/${VERSION}/reports/$${a}/snyk.json"; \
	done

.PHONY: snyk-all
snyk-all: check-variable-ARCH
	@find ./tools -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | xargs -I {} make snyk IMAGE={} ARCH=${ARCH}

.PHONY: scan
scan: dockle grype trivy snyk

.PHONY: scan-all
scan-all: check-variable-ARCH
	@for a in $$(echo "${ARCH}" | sed "s/,/ /g"); do \
		find ./tools -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | xargs -I {} make scan IMAGE={} ARCH=${ARCH}
	done

.PHONY: render
render: render-dockle render-grype render-trivy render-snyk

.PHONY: render-dockle
render-dockle: check-variable-ARCH check-variable-IMAGE check-variable-VERSION
	@export KIND=$(shell $(MAKE) image-kind IMAGE=${IMAGE}) && \
	for a in $$(echo "${ARCH}" | sed "s/,/ /g"); do \
		ekdo render dockle \
			--output-dir=dist/$${KIND}/${IMAGE}/${VERSION}/renders/$${a} \
			dist/$${KIND}/${IMAGE}/${VERSION}/reports/$${a}/dockle.json; \
	done

.PHONY: render-grype
render-grype: check-variable-ARCH check-variable-IMAGE check-variable-VERSION
	@export KIND=$(shell $(MAKE) image-kind IMAGE=${IMAGE}) && \
	for a in $$(echo "${ARCH}" | sed "s/,/ /g"); do \
		ekdo render grype \
			--output-dir=dist/$${KIND}/${IMAGE}/${VERSION}/renders/$${a} \
			dist/$${KIND}/${IMAGE}/${VERSION}/reports/$${a}/grype.json; \
	done

.PHONY: render-trivy
render-trivy: check-variable-ARCH check-variable-IMAGE check-variable-VERSION
	@export KIND=$(shell $(MAKE) image-kind IMAGE=${IMAGE}) && \
	for a in $$(echo "${ARCH}" | sed "s/,/ /g"); do \
		ekdo render trivy \
			--output-dir=dist/$${KIND}/${IMAGE}/${VERSION}/renders/$${a} \
			dist/$${KIND}/${IMAGE}/${VERSION}/reports/$${a}/trivy.json; \
	done

.PHONY: render-snyk
render-snyk: check-variable-ARCH check-variable-IMAGE check-variable-VERSION
	@export KIND=$(shell $(MAKE) image-kind IMAGE=${IMAGE}) && \
	for a in $$(echo "${ARCH}" | sed "s/,/ /g"); do \
		ekdo render snyk \
			--output-dir=dist/$${KIND}/${IMAGE}/${VERSION}/renders/$${a} \
			dist/$${KIND}/${IMAGE}/${VERSION}/reports/$${a}/snyk.json; \
	done

.PHONY: prepare-gh-pages
prepare-gh-pages: check-variable-IMAGE check-variable-VERSION
	export KIND=$(shell $(MAKE) image-kind IMAGE=${IMAGE}) && \
	${PROJECT_DIR}/scripts/prepare-gh-pages.sh $${KIND} ${IMAGE} ${VERSION}
