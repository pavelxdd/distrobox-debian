#!/usr/bin/env bash
set -e

version="$1"
priority="$2"

for pkg in \
  "clang-${version}" \
  "llvm-${version}" \
  "lldb-${version}" \
  "lld-${version}" \
; do
  if [ "$(dpkg-query -W -f='${Status}' "${pkg}" 2>/dev/null | grep -c "ok installed")" -eq 1 ]; then
    dpkg-query -L "${pkg}" | grep "^/usr/bin/" | grep "\-${version}\$" | while read -r link; do
      path="${link%-"${version}"}"
      name="$(basename "${path}")"
      update-alternatives --force --remove-all "${name}" 2>/dev/null | true
      update-alternatives --force --install "${path}" "${name}" "${link}" "${priority}"
      update-alternatives --auto "${name}"
    done
  fi
done
