# Dev Container Features: ZMK Feature Template

> This repo provides a starting point and example for creating custom dev container Features, hosted for free on GitHub Container Registry. The example in this repository follows the [dev container Feature distribution specification](https://containers.dev/implementors/features-distribution/).
).

## Example Contents

This repository contains a single Feature: `zmk`. This Feature serves as a template for implementing your own dev container Feature. Below is a sample `devcontainer.json` alongside example usage of the Feature.

### `zmk`

Running `zmk` inside the built container will execute the logic provided in its `install.sh` script. You can customize its behavior via options defined in its `devcontainer-feature.json`.

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/<your-org>/<your-repo>/zmk:0": {
            // Add options here if defined in devcontainer-feature.json
        }
    }
}
```

## Repo and Feature Structure

This repository has a `src` folder. Each Feature has its own sub-folder, containing at least a `devcontainer-feature.json` and an entrypoint script `install.sh`.

```
├── src
│   └── zmk
│       ├── devcontainer-feature.json
│       └── install.sh
```

An [implementing tool](https://containers.dev/supporting#tools) will composite [the documented dev container properties](https://containers.dev/implementors/features/#devcontainer-feature-json-properties) from the feature's `devcontainer-feature.json` file, and execute the `install.sh` entrypoint script in the container during build time. Implementing tools are also free to process attributes under the `customizations` property as desired.

### Options

All available options for a Feature should be declared in the `devcontainer-feature.json`. The syntax for the `options` property can be found in the [devcontainer Feature json properties reference](https://containers.dev/implementors/features/#devcontainer-feature-json-properties).

Options are exported as Feature-scoped environment variables. The option name is capitalized and sanitized according to [option resolution](https://containers.dev/implementors/features/#option-resolution).

```bash
#!/bin/bash

echo "Activating feature 'zmk'"
echo "The provided option is: ${OPTION_NAME}"

...
```

## Distributing Features

### Versioning

Features are individually versioned by the `version` attribute in a Feature's `devcontainer-feature.json`. Features are versioned according to the semver specification. More details can be found in [the dev container Feature specification](https://containers.dev/implementors/features/#versioning).

### Publishing

> NOTE: The Distribution spec can be [found here](https://containers.dev/implementors/features-distribution/).
>
> While any registry [implementing the OCI Distribution spec](https://github.com/opencontainers/distribution-spec) can be used, this template will leverage GHCR (GitHub Container Registry) as the backing registry.

Features are meant to be easily sharable units of dev container configuration and installation code.

This repo contains a **GitHub Action** [workflow](.github/workflows/release.yaml) that will publish each Feature to GHCR.

*Allow GitHub Actions to create and approve pull requests* should be enabled in the repository's `Settings > Actions > General > Workflow permissions` for auto generation of `src/<feature>/README.md` per Feature (which merges any existing `src/<feature>/NOTES.md`).

By default, each Feature will be prefixed with the `<owner>/<repo>` namespace. For example, the Feature in this repository can be referenced in a `devcontainer.json` with:

```
ghcr.io/<your-org>/<your-repo>/zmk:1
```

The provided GitHub Action will also publish a second "metadata" package with just the namespace, eg: `ghcr.io/<your-org>/<your-repo>`. This contains information useful for tools aiding in Feature discovery.

### Marking Feature Public

Note that by default, GHCR packages are marked as `private`. To stay within the free tier, Features need to be marked as `public`.

This can be done by navigating to the Feature's "package settings" page in GHCR, and setting the visibility to 'public`. The URL may look something like:

```
https://github.com/users/<owner>/packages/container/<repo>%2F<featureName>/settings
```

### Adding Features to the Index

If you'd like your Feature to appear in the [public index](https://containers.dev/features) so that other community members can find it, you can do the following:

* Go to [github.com/devcontainers/devcontainers.github.io](https://github.com/devcontainers/devcontainers.github.io)
     * This is the GitHub repo backing the [containers.dev](https://containers.dev/) spec site
* Open a PR to modify the [collection-index.yml](https://github.com/devcontainers/devcontainers.github.io/blob/gh-pages/_data/collection-index.yml) file

This index is from where [supporting tools](https://containers.dev/supporting) like [VS Code Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) and [GitHub Codespaces](https://github.com/features/codespaces) surface Features for their dev container creation UI.

#### Using private Features in Codespaces

For any Features hosted in GHCR that are kept private, the `GITHUB_TOKEN` access token in your environment will need to have `package:read` and `contents:read` for the associated repository.

Many implementing tools use a broadly scoped access token and will work automatically. GitHub Codespaces uses repo-scoped tokens, and therefore you'll need to add the permissions in `devcontainer.json`

An example `devcontainer.json` can be found below.

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
     "ghcr.io/<your-org>/<your-repo>/zmk:1": {
            // Add options here if defined
        }
    },
    "customizations": {
        "codespaces": {
            "repositories": {
                "<your-org>/<your-repo>": {
                    "permissions": {
                        "packages": "read",
                        "contents": "read"
                    }
                }
            }
        }
    }
}
```
