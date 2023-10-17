#!/usr/bin/env bash
set -e

version="$1"
priority="$2"

pkgs=(
  "gcc-${version}"
  "g++-${version}"
  "cpp-${version}"
  "c++-${version}"
  "gcc-${version}-arm-linux-gnueabihf"
  "g++-${version}-arm-linux-gnueabihf"
  "cpp-${version}-arm-linux-gnueabihf"
  "c++-${version}-arm-linux-gnueabihf"
  "gcc-${version}-aarch64-linux-gnu"
  "g++-${version}-aarch64-linux-gnu"
  "cpp-${version}-aarch64-linux-gnu"
  "c++-${version}-aarch64-linux-gnu"
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

update-alternatives --force --remove-all cc 2> /dev/null | true
update-alternatives --force --install /usr/bin/cc cc /usr/bin/gcc "${priority}"
update-alternatives --force --set cc /usr/bin/gcc

update-alternatives --force --remove-all cxx 2> /dev/null | true
update-alternatives --force --install /usr/bin/cxx cxx /usr/bin/g++ "${priority}"
update-alternatives --force --set cxx /usr/bin/g++

update-alternatives --force --remove-all c++ 2> /dev/null | true
update-alternatives --force --install /usr/bin/c++ c++ /usr/bin/g++ "${priority}"
update-alternatives --force --set c++ /usr/bin/g++

update-alternatives --force --remove-all "c++-${version}" 2> /dev/null | true
update-alternatives --force --install "/usr/bin/c++-${version}" "c++-${version}" "/usr/bin/g++-${version}" "${priority}"
update-alternatives --force --set "c++-${version}" "/usr/bin/g++-${version}"

pkgs=(
  "gcc"
  "gcc-${version}"
  "g++"
  "g++-${version}"
  "cpp"
  "cpp-${version}"
  "c++"
  "c++-${version}"
)

for pkg in "${pkgs[@]}"; do
  name="x86_64-pc-linux-gnu-${pkg}"
  update-alternatives --force --remove-all "${name}" 2> /dev/null | true
  update-alternatives --force --install "/usr/bin/${name}" "${name}" "/usr/bin/${pkg}" "${priority}"
  update-alternatives --force --set "${name}" "/usr/bin/${pkg}"
done
