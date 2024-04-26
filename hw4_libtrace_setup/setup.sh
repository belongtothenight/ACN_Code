#!/bin/bash
#
# Clone instead of repo but release if possible
# Version check rely on automake
# Network activities are put in the front section

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
wandio_release_url="https://github.com/LibtraceTeam/wandio/archive/refs/tags/4.2.6-1.tar.gz"
wandio_name="wandio"
libtrace_release_url="https://github.com/LibtraceTeam/libtrace/archive/refs/tags/4.0.24-1.tar.gz"
libtrace_name="libtrace"
libtrace_turorial_repo_url="https://github.com/ylai/libtrace_tutorial.git"

libwandder_file="${libwandder_name}-${libwandder_release_url##*/}"
libwandder_ln="${libwandder_file//.tar.gz}"
wandio_file="${wandio_name}-${wandio_release_url##*/}"
wandio_ln="${wandio_file//.tar.gz}"
libtrace_file="${libtrace_name}-${libtrace_release_url##*/}"
libtrace_ln="${libtrace_file//.tar.gz}"

# Install mutual dependencies
echo "Installing mutual dependencies"
sudo apt install -y build-essential git wget

# Pull bash functions
echo "Downloading bash functions"
sudo wget $wget_flags "${program_install_dir}/${bash_function_file}" "${bash_function_url}"

echo "Sourcing bash functions"
source "${program_install_dir}/${bash_function_file}"

# Download libwandder release (wandio dependency)
echo_notice "$this_script" "base" "Downloading libwandder release"
if [ $script_stat == "dev" ]; then
    err_conti_exec "sudo wget $wget_flags ${program_install_dir}/${libwandder_file} ${libwandder_release_url}" 1 5 "${this_script}" "base" 1
elif [ $script_stat == "prod" ]; then
    err_retry_exec "sudo wget $wget_flags ${program_install_dir}/${libwandder_file} ${libwandder_release_url}" 1 5 "${this_script}" "base" 1
fi

# Download wandio release (libtrace dependency)
echo_notice "$this_script" "base" "Downloading wandio release"
if [ $script_stat == "dev" ]; then
    err_conti_exec "sudo wget $wget_flags ${program_install_dir}/${wandio_file} ${wandio_release_url}" 1 5 "${this_script}" "base" 1
elif [ $script_stat == "prod" ]; then
    err_retry_exec "sudo wget $wget_flags ${program_install_dir}/${wandio_file} ${wandio_release_url}" 1 5 "${this_script}" "base" 1
fi

# Clone libtrace repo
echo_notice "$this_script" "base" "Cloning libtrace repo"
if [ $script_stat == "dev" ]; then
    err_conti_exec "sudo wget $wget_flags ${program_install_dir}/${libtrace_file} ${libtrace_release_url}" 1 5 "${this_script}" "base" 1
elif [ $script_stat == "prod" ]; then
    err_retry_exec "sudo wget $wget_flags ${program_install_dir}/${libtrace_file} ${libtrace_release_url}" 1 5 "${this_script}" "base" 1
fi

# Clone libtrace tutorial repo
echo_notice "$this_script" "base" "Cloning libtrace tutorial repo"
if [ $script_stat == "dev" ]; then
    err_conti_exec "sudo git clone ${libtrace_turorial_repo_url} ${program_install_dir}/libtrace_tutorial" 1 5 "${this_script}" "base" 1
elif [ $script_stat == "prod" ]; then
    err_retry_exec "sudo git clone ${libtrace_turorial_repo_url} ${program_install_dir}/libtrace_tutorial" 1 5 "${this_script}" "base" 1
fi

# Install wandio dependencies
echo_notice "$this_script" "base" "Installing wandio dependencies"
err_retry_exec "aptins automake"                1 5 "${this_script}" "base" 1 # >= 1.9
err_retry_exec "aptins libpthread-stubs0-dev"   1 5 "${this_script}" "base" 1 # (optional)
err_retry_exec "aptins zlib1g-dev"              1 5 "${this_script}" "base" 1 # (optional)
err_retry_exec "aptins libbz2-dev"              1 5 "${this_script}" "base" 1 # (optional)
err_retry_exec "aptins liblzma-dev"             1 5 "${this_script}" "base" 1 # (optional)
err_retry_exec "aptins liblzo2-dev"             1 5 "${this_script}" "base" 1 # (optional)
err_retry_exec "aptins liblz4-dev"              1 5 "${this_script}" "base" 1 # (optional)
err_retry_exec "aptins libzstd-dev"             1 5 "${this_script}" "base" 1 # (optional)

# Install libtrace dependencies
echo_notice "$this_script" "base" "Installing libtrace dependencies"
#err_retry_exec "aptins automake"                1 5 "${this_script}" "base" 1 # >= 1.9, done
err_retry_exec "aptins libpcap-dev"             1 5 "${this_script}" "base" 1 # >= 0.8
err_retry_exec "aptins flex"                    1 5 "${this_script}" "base" 1
err_retry_exec "aptins bison"                   1 5 "${this_script}" "base" 1
err_retry_exec "aptins pkg-config"              1 5 "${this_script}" "base" 1
#err_retry_exec "aptins libwandio-dev"           1 5 "${this_script}" "base" 1 # build from source
err_retry_exec "aptins libyaml-dev"             1 5 "${this_script}" "base" 1 # (optional)
err_retry_exec "aptins libssl-dev"              1 5 "${this_script}" "base" 1 # (optional) for libcrypto
err_retry_exec "aptins libncurses5-dev"         1 5 "${this_script}" "base" 1 # (optional) for libncurses
err_retry_exec "aptins libncursesw5-dev"        1 5 "${this_script}" "base" 1 # (optional) for libncurses

# Extract .tar.gz files
echo_notice "$this_script" "base" "Extracting .tar.gz files"
sudo tar $tar_flags "${program_install_dir}/${libwandder_file}" -C "${program_install_dir}"
sudo tar $tar_flags "${program_install_dir}/${wandio_file}" -C "${program_install_dir}"
sudo tar $tar_flags "${program_install_dir}/${libtrace_file}" -C "${program_install_dir}"

# Create symbolic links
echo_notice "$this_script" "base" "Creating symbolic links"
if [ $script_stat == "dev" ]; then
    err_conti_exec "sudo ln -s ${program_install_dir}/${libwandder_ln} ${program_install_dir}/${libwandder_name}" 1 5 "${this_script}" "base" 1
    err_conti_exec "sudo ln -s ${program_install_dir}/${wandio_ln} ${program_install_dir}/${wandio_name}" 1 5 "${this_script}" "base" 1
    err_conti_exec "sudo ln -s ${program_install_dir}/${libtrace_ln} ${program_install_dir}/${libtrace_name}" 1 5 "${this_script}" "base" 1
elif [ $script_stat == "prod" ]; then
    sudo ln -s "${program_install_dir}/${libwandder_ln}" "${program_install_dir}/${libwandder_name}"
    sudo ln -s "${program_install_dir}/${wandio_ln}" "${program_install_dir}/${wandio_name}"
    sudo ln -s "${program_install_dir}/${libtrace_ln}" "${program_install_dir}/${libtrace_name}"
fi

# Build libwandder

# End of file
echo_notice "$this_script" "base" "Setup complete"
