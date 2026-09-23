#!/usr/bin/env bash
#
# publish.sh — build and publish the docs-portfolio site.
#
# SAFE BY DESIGN:
#   * Only touches this directory and the NEW repo "docs-portfolio".
#   * Never opens, edits, or pushes to pvawsome/road-accident-dashboard.
#   * Every step is printed before it runs.
#
# Usage:  bash publish.sh
#
set -euo pipefail

cd "$(dirname "$0")"

REPO="docs-portfolio"
SITE_URL="https://pvawsome.github.io/${REPO}/"

step () { printf '\n\033[1;34m==> %s\033[0m\n' "$1"; }

# ---------------------------------------------------------------------------
step "1/6  Create a virtual environment and install MkDocs Material"
python3 -m venv .venv
# shellcheck disable=SC1091
source .venv/bin/activate
python -m pip install --quiet --upgrade pip
python -m pip install --quiet -r requirements.txt
python -c "import mkdocs; print('mkdocs', mkdocs.__version__, 'ready')"

# ---------------------------------------------------------------------------
step "2/6  Build the site (local verification before anything is published)"
mkdocs build
echo "Build OK — static output is in ./site/"

# ---------------------------------------------------------------------------
step "3/6  Initialise git and commit"
if [ ! -d .git ]; then
  git init -b main
fi
git add -A
git -c user.name="$(git config --global user.name || echo PPar)" \
    -c user.email="$(git config --global user.email || echo pavanraj.parth@gmail.com)" \
    commit -m "Add technical writing portfolio site with sample 01 (staging-to-typed SQL Server pipeline)"

# ---------------------------------------------------------------------------
step "4/6  Check GitHub authentication"
if ! gh auth status >/dev/null 2>&1; then
  echo "Not logged in to GitHub. Starting device-code login."
  echo "A one-time code will be shown; enter it at the URL that appears."
  gh auth login --hostname github.com --git-protocol https --web
fi
gh auth status

# ---------------------------------------------------------------------------
step "5/6  Create the new public repo and push"
if gh repo view "pvawsome/${REPO}" >/dev/null 2>&1; then
  echo "Repo pvawsome/${REPO} already exists — pushing to it."
  git remote get-url origin >/dev/null 2>&1 || \
    git remote add origin "https://github.com/pvawsome/${REPO}.git"
  git push -u origin main
else
  gh repo create "${REPO}" \
    --public \
    --description "Technical writing samples: data pipelines, SQL, and AI systems documented from hands-on engineering work." \
    --source=. \
    --remote=origin \
    --push
fi

# ---------------------------------------------------------------------------
step "6/6  Deploy the built site to GitHub Pages (gh-pages branch)"
mkdocs gh-deploy --force

echo
echo "==================================================================="
echo " Done. Site should appear within ~60 seconds at:"
echo "   ${SITE_URL}"
echo
echo " If GitHub asks, set: Settings -> Pages -> Source = gh-pages / root"
echo "==================================================================="
echo
echo " Verify the other repo is untouched:"
echo "   gh repo view pvawsome/road-accident-dashboard --json pushedAt,defaultBranchRef"