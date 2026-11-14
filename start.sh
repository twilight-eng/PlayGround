#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"
PORT="${PORT:-3000}"
OPENCODE_WEB_DIR="${OPENCODE_WEB_DIR:-/home/runner/work/_temp/omgithub-web}"
export PORT

timed() {
  local label="$1"
  shift
  echo "[timing] ${label}"
  /usr/bin/time -p "$@"
}

timed 'dependency install' npm ci --no-audit --no-fund
timed 'production build' npm run build
timed 'deployment metadata' node --input-type=module -e '
  import { mkdirSync, writeFileSync } from "node:fs";
  import { resolve } from "node:path";
  const project = resolve(process.argv[1]);
  const directory = resolve(project, "dist");
  mkdirSync(process.argv[2], { recursive: true });
  writeFileSync(resolve(process.argv[2], "deployment-output.json"), JSON.stringify({ project, directory }));
' "$PROJECT_DIR" "$OPENCODE_WEB_DIR"

timed 'foreground static preview server' node --input-type=module -e '
  import { preview } from "vite";
  const server = await preview({
    configFile: false,
    root: process.cwd(),
    preview: {
      host: "0.0.0.0",
      port: Number(process.env.PORT),
      strictPort: true,
      allowedHosts: [".omgithub.com", ".lolgames.net", "localhost"],
    },
  });
  server.printUrls();
  for (const signal of ["SIGINT", "SIGTERM"]) process.once(signal, async () => { await server.close(); process.exit(0); });
'
