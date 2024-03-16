# Mecha Images

Collection of secure OCI images for CI/CD pipelines.

Images are built using [Chainguard][https://www.chainguard.dev]'s [Melange][https://github.com/chainguard-dev/melange]
and [Apko][https://github.com/chainguard-dev/apko] tools, resulting in small, cve-free artifacts that reduce the
attack surface of your CI/CD pipelines, while providing a handy set of tools for your builds.

They are divided in `Tools` and `Collections`, where `Tools` are single-tool images, while `Collections`
are multi-purpose ones targeting common use cases for well-established languages and frameworks.

We strive for full automation of the build and update process via the [updatecli](https://www.updatecli.io) tool and
the use of [GitHub Actions](https://github.com/features/actions) for the CI/CD pipeline.

## Supported Images

- [checkmake](https://github.com/mrtazz/checkmake)
- [file-lint](https://github.com/cytopia/docker-file-lint)
- [jsonlint](https://github.com/zaach/jsonlint)
- [ls-lint](https://github.com/loeffel-io/ls-lint)
- [yamlfmt](https://github.com/google/yamlfmt)
- [yamllint](https://github.com/adrienverge/yamllint)
