#!/usr/bin/env bash
set -euo pipefail

flutter_version="3.35.7"
flutter_dir="${HOME}/flutter-sdk"
flutter_archive="/tmp/flutter-${flutter_version}.tar.xz"

if [ ! -x "${flutter_dir}/bin/flutter" ]; then
  curl --fail --location --silent --show-error \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${flutter_version}-stable.tar.xz" \
    --output "${flutter_archive}"
  tar -xJf "${flutter_archive}" -C "${HOME}"
  mv "${HOME}/flutter" "${flutter_dir}"
fi

export PATH="${flutter_dir}/bin:${PATH}"
# Vercel may unpack Flutter with a different owner; Flutter invokes Git internally.
git config --global --add safe.directory "${flutter_dir}"
flutter config --enable-web
flutter pub get
flutter build web --release
