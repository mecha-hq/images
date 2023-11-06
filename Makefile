# check-variable-%: Check if the variable is defined.
check-variable-%:
	@[[ "${${*}}" ]] || (echo '*** Please define variable `${*}` ***' && exit 1)

.PHONY: keygen melange apko docker-load

keygen:
	@docker run --rm -v $${PWD}:/work -w /work cgr.dev/chainguard/melange:latest keygen

melange: check-variable-TOOL
	@docker run --privileged --rm \
		-v $${PWD}:/work -w /work \
		cgr.dev/chainguard/melange:latest \
		build --arch=arm64 --debug \
			--signing-key=melange.rsa \
			--out-dir=${TOOL}/packages \
			${TOOL}/melange.yaml

apko: check-variable-TOOL
	@mkdir -p "${TOOL}/sboms"
	@docker run --rm \
		-v $${PWD}:/work -w /work \
		cgr.dev/chainguard/apko:latest \
		build --arch=arm64 --debug \
			--keyring-append=melange.rsa.pub \
			--sbom-path=${TOOL}/sboms \
			${TOOL}/apko.yaml tenwarp/${TOOL}:latest ${TOOL}/oci-image.tar

docker-load: check-variable-TOOL
	@docker load -i ${TOOL}/oci-image.tar

.PHONY: dockle grype trivy snyk

dockle: check-variable-TOOL
	@dockle -f json -o "reports/${TOOL}/dockle.json" --debug "tenwarp/${TOOL}:latest-arm64"

grype: check-variable-TOOL
	@grype -o json --file "reports/${TOOL}/grype.json" "tenwarp/${TOOL}:latest-arm64" -vv

trivy: check-variable-TOOL
	@trivy image -d -f json -o "reports/${TOOL}/trivy.json" "tenwarp/${TOOL}:latest-arm64"

snyk: check-variable-TOOL
	@snyk container test -d --json-file-output="reports/${TOOL}/snyk.json" --org=275c6446-f43f-4876-a84d-4c71738b5f7f "tenwarp/${TOOL}:latest-arm64"
