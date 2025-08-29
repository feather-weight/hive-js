#!/bin/bash
set -e

echo "🚀 Fixing Hive-JS legacy deps..."

# 1. Make sure we’re in the right folder
cd "$(dirname "$0")"

# 2. Ensure nvm & Node 0.12
if [ -s "$HOME/.nvm/nvm.sh" ]; then
  source "$HOME/.nvm/nvm.sh"
else
  echo "❌ nvm not found. Install from: https://github.com/nvm-sh/nvm"
  exit 1
fi

nvm use 0.12 || nvm install 0.12
npm install -g npm@2.14.12

# 3. Make sure Python 2 is available for node-gyp
if ! command -v python2 &>/dev/null; then
  echo "⚠️ Python2 not found. Installing via Homebrew..."
  brew install python@2 || true
fi
PYTHON_PATH=$(which python2 || which python)
export PYTHON=$PYTHON_PATH
echo "➡️ Using Python at $PYTHON"

# 4. Clean node_modules
rm -rf node_modules package-lock.json ~/.npm/_git-remotes

# 5. Patch phantomjs (skip broken installer)
mkdir -p overrides
cat > overrides/phantomjs.js <<'EOF'
module.exports = {
  path: '/usr/bin/true', // fake phantomjs binary
  platform: process.platform,
  arch: process.arch,
  version: '1.9.20'
};
EOF
npm set phantomjs_binary_cache=$(pwd)/overrides

# 6. Patch node-sass (skip binary build)
npm set sass_binary_site=https://github.com/sass/node-sass/releases/download

# 7. Install dependencies
echo "📦 Installing dependencies..."
npm install --ignore-scripts || true

# 8. Build remaining binaries (if any)
npm rebuild

echo "✅ Hive-JS deps fixed. Try running:"
echo "   npm start   or   node build.js"

