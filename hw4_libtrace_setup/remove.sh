#!/bin/bash

# var
script_stat="dev" # dev, prod
wget_flags="-nv --show-progress --output-document"
tar_flags="-xzf"
this_script="ACN_Code/hw4_libtrace_setup/setup.sh"
program_install_dir="/opt"
bash_function_url="https://raw.githubusercontent.com/belongtothenight/bash_scripts/main/src/functions.sh"
bash_function_file="functions.sh"
libwandder_release_url="https://github.com/LibtraceTeam/libwandder/archive/refs/tags/2.0.11-1.tar.gz"
libwandder_name="libwandder"
libwandder_file="${libwandder_name}-${libwandder_release_url##*/}"
libwandder_ln="${libwandder_file//.tar.gz}"
wandio_release_url="https://github.com/LibtraceTeam/wandio/archive/refs/tags/4.2.6-1.tar.gz"
wandio_name="wandio"
wandio_file="${wandio_name}-${wandio_release_url##*/}"
wandio_ln="${wandio_file//.tar.gz}"
libtrace_release_url="https://github.com/LibtraceTeam/libtrace/archive/refs/tags/4.0.24-1.tar.gz"
libtrace_name="libtrace"
libtrace_file="${libtrace_name}-${libtrace_release_url##*/}"
libtrace_ln="${libtrace_file//.tar.gz}"
libtrace_turorial_repo_url="https://github.com/ylai/libtrace_tutorial.git"

set -e
source "${program_install_dir}/${bash_function_file}"

# Remove functions file
echo_notice "$this_script" "base" "Removing functions file"
sudo rm -f "${program_install_dir}/${bash_function_file}"

# Remove libwandder
echo_notice "$this_script" "base" "Removing libwandder"
sudo rm -f "${program_install_dir}/${libwandder_file}"
sudo rm -rf "${program_install_dir}/${libwandder_ln}"
sudo rm -f "${program_install_dir}/${libwandder_name}"

# Remove wandio
echo_notice "$this_script" "base" "Removing wandio"
sudo rm -f "${program_install_dir}/${wandio_file}"
sudo rm -rf "${program_install_dir}/${wandio_ln}"
sudo rm -f "${program_install_dir}/${wandio_name}"

# Remove libtrace
echo_notice "$this_script" "base" "Removing libtrace"
sudo rm -f "${program_install_dir}/${libtrace_file}"
sudo rm -rf "${program_install_dir}/${libtrace_ln}"
sudo rm -f "${program_install_dir}/${libtrace_name}"

# Remove libtrace tutorial repo
echo_notice "$this_script" "base" "Removing libtrace tutorial repo"
sudo rm -rf "${program_install_dir}/libtrace_tutorial"

# End of file
echo_notice "$this_script" "base" "Cleanup complete"
