# OAI Compatible Copilot Persistence (devcontainer-feature)

Persists [OAI Compatible Copilot](https://marketplace.visualstudio.com/items?itemName=johnny-zhao.oai-compatible-copilot) settings and extension state across devcontainer rebuilds.

## How it works

Instead of mounting directly to the VS Code server path (which varies by user and conflicts with other features), this feature:

1. Mounts a named volume to a neutral location (`/usr/local/share/oaicopilot-persist/...`)
2. Creates a symlink from the actual extension globalStorage path to that volume at build time
3. At runtime, Docker populates the mount with persisted data from previous builds

## Usage

### Per-project (devcontainer.json)

```json
{
  "features": {
    "ghcr.io/yourname/devcontainer-features/oaicopilot-persist:1": {}
  }
}
```

### Global (all devcontainers)

Add to your VS Code **User** `settings.json`:

```json
{
  "dev.containers.defaultFeatures": {
    "ghcr.io/yourname/devcontainer-features/oaicopilot-persist:1": {}
  }
}
```

## Volumes created

| Volume name | What it stores |
|-------------|----------------|
| `oaicopilot-globalstorage` | Extension state, model configs, cache |
| `vscode-user-settings` | VS Code settings.json (shared with kilocode-persist) |

## Coexistence with kilocode-persist

Both features use the **same** `vscode-user-settings` volume name for the settings directory, so they mount the same shared volume without conflict. Each feature has its own separate volume for extension-specific globalStorage.

## Publishing

```bash
cd src/oaicopilot-persist
devcontainer features publish -r ghcr.io -n yourname/devcontainer-features .
```

Or use the GitHub Action from the template repo.
