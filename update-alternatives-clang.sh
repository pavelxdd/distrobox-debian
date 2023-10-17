#!/usr/bin/env bash
set -e

version="$1"
priority="$2"

pkgs=(
  "clang-${version}"
  "clang-format-${version}"
  "clang-tidy-${version}"
  "clang-tools-${version}"
  "lld-${version}"
  "lldb-${version}"
  "llvm-${version}-linker-tools"
  "llvm-${version}-runtime"
  "llvm-${version}-tools"
  "llvm-${version}"
)

for pkg in "${pkgs[@]}"; do
  if [ "$(dpkg-query -W -f='${Status}' "${pkg}" 2> /dev/null | grep -c "ok installed")" -eq 1 ]; then
    dpkg-query -L "${pkg}" | grep "^/usr/bin/" | grep "\-${version}\$" | while read -r link; do
      path="${link%-"${version}"}"
      name="$(basename "${path}")"
      update-alternatives --force --remove-all "${name}" 2> /dev/null | true
      update-alternatives --force --install "${path}" "${name}" "${link}" "${priority}"
      update-alternatives --auto "${name}"
    done
  fi
done

pkgs=(
  "clang"
  "clang-${version}"
  "clang++"
  "clang++-${version}"
)

for pkg in "${pkgs[@]}"; do
  name="x86_64-pc-linux-gnu-${pkg}"
  update-alternatives --force --remove-all "${name}" 2> /dev/null | true
  update-alternatives --force --install "/usr/bin/${name}" "${name}" "/usr/bin/${pkg}" "${priority}"
  update-alternatives --force --set "${name}" "/usr/bin/${pkg}"
done
