#!/usr/bin/env bash
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

setup_git() {
  (umask 077; printf 'machine %s login gitlab-ci-token password %s\n' "$CI_SERVER_HOST" "$CI_JOB_TOKEN" >> ~/.netrc)
}

setup_node() {
  local tools_dir=/tmp/openproject-node
  if [[ "$(node --version)" != "v$NODE_VERSION" ]]; then
    local arch archive
    case "$(uname -m)" in
      x86_64) arch=x64 ;;
      aarch64) arch=arm64 ;;
      *) return 1 ;;
    esac
    archive="node-v${NODE_VERSION}-linux-${arch}.tar.gz"
    mkdir -p "$tools_dir"
    (
      cd "$tools_dir" || exit 1
      curl -fsSLO --retry 3 "https://nodejs.org/dist/v${NODE_VERSION}/$archive"
      curl -fsSL --retry 3 "https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt" |
        grep -F "  $archive" | sha256sum --check -
      tar -xzf "$archive" --strip-components=1
    )
  fi
  export PATH="$tools_dir/bin:$PATH"
  export pnpm_config_store_dir=/tmp/openproject-pnpm-store
  npm install --global --prefix "$tools_dir" "pnpm@$PNPM_VERSION"
}

install_bundle() {
  local version
  version=$(awk '/^BUNDLED WITH$/ { getline; print $1 }' "${BUNDLE_GEMFILE:-Gemfile}.lock")
  if ! gem list --installed bundler --version "$version" >/dev/null; then
    gem install bundler --no-document --version "$version"
  fi
  bundle "_${version}_" install --retry 3
}

setup_rails() {
  sudo apt-get update -qq
  if ! apt-cache show postgresql-client-17 >/dev/null 2>&1; then
    local codename
    codename=$(lsb_release -cs)
    curl -fsSL --retry 3 https://www.postgresql.org/media/keys/ACCC4CF8.asc |
      sudo tee /usr/share/keyrings/pgdg.asc >/dev/null
    echo "deb [signed-by=/usr/share/keyrings/pgdg.asc] https://apt.postgresql.org/pub/repos/apt $codename-pgdg main" |
      sudo tee /etc/apt/sources.list.d/pgdg.list >/dev/null
    sudo apt-get update -qq
  fi
  sudo apt-get install -y --no-install-recommends postgresql-client-17 imagemagick libclang-dev libpq-dev subversion
  export PATH="/usr/lib/postgresql/17/bin:$PATH"
  install_bundle
  printf '%s:\n  url: <%%= ENV.fetch("DATABASE_URL") %%>\n' "$RAILS_ENV" > config/database.yml
}

start_hocuspocus() {
  pnpm -C extensions/op-blocknote-hocuspocus install --frozen-lockfile --prod
  SECRET="$OPENPROJECT_COLLABORATIVE__EDITING__HOCUSPOCUS__SECRET" \
    pnpm -C extensions/op-blocknote-hocuspocus start >tmp/hocuspocus.log 2>&1 &
  local pid=$!
  for _ in {1..60}; do
    if (: >/dev/tcp/127.0.0.1/1234) 2>/dev/null; then return 0; fi
    kill -0 "$pid" 2>/dev/null || break
    sleep 1
  done
  cat tmp/hocuspocus.log >&2
  return 1
}
