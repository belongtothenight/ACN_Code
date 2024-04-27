#!/bin/bash
#
# Packages installed using dpkg/apt are not removed

# ====================================================================================
# Init
# ====================================================================================
bash_function_file="./functions.sh"

echo "Sourcing bash functions"
source "${bash_function_file}" || { echo 'source failed'; exit 1; } # Enter fail-exit mode
source "./common_functions.sh"
load_preset "./config.ini"

# ====================================================================================
# Remove functions file
# ====================================================================================
echo_notice "$this_script" "base" "Removing functions file"
sudo rm -f "${bash_function_file}"

# ====================================================================================
# Remove uthash
# ====================================================================================
if [ $task_uthash == 1 ]; then
    echo_notice "$this_script" "base" "Removing uthash"
    sudo rm -rf "${program_install_dir}/${uthash_name}"
    sudo rm -f ${system_include_dir}/ut*.h
fi

# ====================================================================================
# Remove libwandder
# ====================================================================================
if [ $task_libwandder == 1 ]; then
    echo_notice "$this_script" "base" "Removing libwandder"
    sudo rm -f ${system_include_dir}/libwandder*.h
    sudo rm -f ${system_lib_dir}/libwandder*
    sudo rm -f "${program_install_dir}/${libwandder_file}"
    sudo rm -rf "${program_install_dir}/${libwandder_ln}"
    sudo rm -f "${program_install_dir}/${libwandder_name}"
fi

# ====================================================================================
# Remove wandio
# ====================================================================================
if [ $task_wandio == 1 ]; then
    echo_notice "$this_script" "base" "Removing wandio"
    sudo rm -f ${system_include_dir}/wandio*.h
    sudo rm -f ${system_lib_dir}/libwandio*
    sudo rm -f "${program_install_dir}/${wandio_file}"
    sudo rm -rf "${program_install_dir}/${wandio_ln}"
    sudo rm -f "${program_install_dir}/${wandio_name}"
fi

# ====================================================================================
# Remove libtrace
# ====================================================================================
if [ $task_libtrace == 1 ]; then
    echo_notice "$this_script" "base" "Removing libtrace"
    sudo rm -f ${system_include_dir}/libtrace*.h
    sudo rm -f ${system_include_dir}/libpacketdump*.h
    sudo rm -rf "${system_include_dir}/${libtrace_name}"
    sudo rm -f ${system_lib_dir}/libtrace*
    sudo rm -rf ${system_lib_dir}/libpacketdump*
    sudo rm -f "${program_install_dir}/${libtrace_file}"
    sudo rm -rf "${program_install_dir}/${libtrace_ln}"
    sudo rm -f "${program_install_dir}/${libtrace_name}"
fi

# ====================================================================================
# Remove libtrace tutorial repo
# ====================================================================================
if [ $task_libtrace_tutorial == 1 ]; then
    echo_notice "$this_script" "base" "Removing libtrace tutorial repo"
    sudo rm -rf "${program_install_dir}/libtrace_tutorial"
fi

# End of file
echo_notice "$this_script" "base" "Cleanup complete"
