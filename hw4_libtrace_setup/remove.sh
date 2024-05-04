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
# Backup files
# ====================================================================================
msg="backup"
if [ $task_uthash == 1 ] || [ $task_libwandder == 1 ] || [ $task_wandio == 1 ] || [ $task_libtrace == 1 ]; then
    echo_notice "$this_script" "$msg" "Backing up files"
    sudo rm -rf "${program_install_dir}/backup_include"
    sudo cp -rf "${system_include_dir}/" "${program_install_dir}/"
    sudo mv "${program_install_dir}/include/" "${program_install_dir}/backup_include/"
    sudo rm -rf "${program_install_dir}/backup_lib"
    sudo cp -rf "${system_lib_dir}/" "${program_install_dir}/"
    sudo mv "${program_install_dir}/lib/" "${program_install_dir}/backup_lib/"
fi

# ====================================================================================
# Remove uthash
# ====================================================================================
msg="remove uthash"
if [ $task_uthash == 1 ]; then
    echo_notice "$this_script" "$msg" "Removing uthash"
    sudo rm -rf "${program_install_dir}/${uthash_name}"
    sudo rm -f ${system_include_dir}/ut*.h
fi

# ====================================================================================
# Remove libwandder
# ====================================================================================
msg="remove libwandder"
if [ $task_libwandder == 1 ]; then
    echo_notice "$this_script" "$msg" "Removing libwandder"
    cd "${program_install_dir}/${libwandder_name}"
    sudo make uninstall
    sudo rm -f "${program_install_dir}/${libwandder_file}"
    sudo rm -rf "${program_install_dir}/${libwandder_ln}"
    sudo rm -f "${program_install_dir}/${libwandder_name}"
fi

# ====================================================================================
# Remove wandio
# ====================================================================================
msg="remove wandio"
if [ $task_wandio == 1 ]; then
    echo_notice "$this_script" "$msg" "Removing wandio"
    cd "${program_install_dir}/${wandio_name}"
    sudo make uninstall
    sudo rm -f "${program_install_dir}/${wandio_file}"
    sudo rm -rf "${program_install_dir}/${wandio_ln}"
    sudo rm -f "${program_install_dir}/${wandio_name}"
fi

# ====================================================================================
# Remove libtrace
# ====================================================================================
msg="remove libtrace"
if [ $task_libtrace == 1 ]; then
    echo_notice "$this_script" "$msg" "Removing libtrace"
    cd "${program_install_dir}/${libtrace_name}"
    sudo make uninstall
    sudo rm -rf "${system_lib_dir}/libpacketdump"
    sudo rmdir "${system_include_dir}/${libtrace_name}"
    sudo rmdir "${system_share_dir}/${libtrace_name}"
    sudo rm -f "${program_install_dir}/${libtrace_file}"
    sudo rm -rf "${program_install_dir}/${libtrace_ln}"
    sudo rm -f "${program_install_dir}/${libtrace_name}"
fi

# ====================================================================================
# Remove libtrace tutorial repo
# ====================================================================================
msg="remove libtrace tutorial"
if [ $task_libtrace_tutorial == 1 ]; then
    echo_notice "$this_script" "$msg" "Removing libtrace tutorial repo"
    sudo rm -rf "${program_install_dir}/libtrace_tutorial"
fi

# End of file
msg="cleanup"
echo_notice "$this_script" "$msg" "Cleanup complete"
