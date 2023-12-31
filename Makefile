.PHONY: check-variable-% image-kind

check-variable-%:
	@[[ "${${*}}" ]] || (echo '*** Please define variable `${*}` ***' && exit 1)

image-kind: check-variable-IMAGE
	@find . -name "${IMAGE}" -type d | cut -d '/' -f -2

.PHONY: keygen melange apko docker-load clean clean-all run

keygen:
	@docker run --rm -v $${PWD}:/work -w /work cgr.dev/chainguard/melange:latest keygen

melange: check-variable-ARCH check-variable-IMAGE
	@export KIND=$$(find . -name "${IMAGE}" -type d | cut -d '/' -f -2) && \
	docker run --privileged --rm \
		-v $${PWD}:/work -w /work \
		cgr.dev/chainguard/melange:latest \
		build --arch=${ARCH} --debug \
			--signing-key=melange.rsa \
			--out-dir=$${KIND}/${IMAGE}/packages \
			$${KIND}/${IMAGE}/melange.yaml

apko: check-variable-ARCH check-variable-IMAGE
	@export KIND=$$(find . -name "${IMAGE}" -type d | cut -d '/' -f -2) && \
	mkdir -p "$${KIND}/${IMAGE}/sboms" && \
	docker run --rm \
		-v $${PWD}:/work -w /work \
		cgr.dev/chainguard/apko:latest \
		build --arch=${ARCH} --debug \
			--keyring-append=melange.rsa.pub \
			--sbom-path=$${KIND}/${IMAGE}/sboms \
			$${KIND}/${IMAGE}/apko.yaml tenwarp/${IMAGE}:latest $${KIND}/${IMAGE}/oci-image.tar

docker-load: check-variable-IMAGE
	@if [ -f tools/${IMAGE}/oci-image.tar ]; then docker load -i tools/${IMAGE}/oci-image.tar; fi
	@if [ -f collections/${IMAGE}/oci-image.tar ]; then docker load -i collections/${IMAGE}/oci-image.tar; fi

run: check-variable-IMAGE check-variable-ARCH clean melange apko docker-load
	@docker run --rm -it tenwarp/${IMAGE}:latest-${ARCH}

clean: check-variable-IMAGE
	@find . -path "*/${IMAGE}/*" -name "oci-image.tar" -type f -delete
	@find . -path "*/${IMAGE}/*" -name "packages" -type d -exec rm -rf {} +
	@find . -path "*/${IMAGE}/*" -name "sboms" -type d -exec rm -rf {} +

clean-all:
	@find . -name "oci-image.tar" -type f -delete
	@find . -name "packages" -type d -exec rm -rf {} +
	@find . -name "sboms" -type d -exec rm -rf {} +

.PHONY: dockle grype trivy snyk scan

dockle: check-variable-ARCH check-variable-IMAGE
	@export KIND=$$(find . -name "${IMAGE}" -type d | cut -d '/' -f -2) && \
	mkdir -p "$${KIND}/${IMAGE}/reports" && \
	dockle -f json -o "$${KIND}/${IMAGE}/reports/dockle.json" --debug "tenwarp/${IMAGE}:latest-${ARCH}"

grype: check-variable-ARCH check-variable-IMAGE
	@export KIND=$$(find . -name "${IMAGE}" -type d | cut -d '/' -f -2) && \
	mkdir -p "$${KIND}/${IMAGE}/reports" && \
	grype -o json --file "$${KIND}/${IMAGE}/reports/grype.json" "tenwarp/${IMAGE}:latest-${ARCH}" -vv

trivy: check-variable-ARCH check-variable-IMAGE
	@export KIND=$$(find . -name "${IMAGE}" -type d | cut -d '/' -f -2) && \
	mkdir -p "$${KIND}/${IMAGE}/reports" && \
	trivy image -d -f json -o "$${KIND}/${IMAGE}/reports/trivy.json" "tenwarp/${IMAGE}:latest-${ARCH}"

snyk: check-variable-ARCH check-variable-IMAGE check-variable-SNYK_ORG
	@export KIND=$$(find . -name "${IMAGE}" -type d | cut -d '/' -f -2) && \
	mkdir -p "$${KIND}/${IMAGE}/reports" && \
	snyk container test -d \
		--org=$${SNYK_ORG} "tenwarp/${IMAGE}:latest-${ARCH}" \
		--json-file-output="$${KIND}/${IMAGE}/reports/snyk.json"

scan: check-variable-ARCH check-variable-IMAGE dockle grype trivy snyk
