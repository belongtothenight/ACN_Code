#!/bin/bash
# functions.sh is required to be sourced before using functions in this file

# value: 1: verbose
verbose=0
message1="ACN_Code/hw4_libtrace_setup/setup.sh"
message2="base"
error_exit_code=1

# Function: load config, check variables, mutual actions
# Usage: source "config.ini"
# Input variable: $1: config.ini
load_preset () {
    if [ $verbose == 1 ]; then
        echo_notice "$message1" "$message2" "Loading preset"
    fi
    parse "$1" ""

    if [ $verbose == 1 ]; then
        echo_notice "$message1" "$message2" "Checking variables"
    fi
    #[ PARAM - TASKS ] X 5
    check_var task_uthash                   $error_exit_code
    check_var task_libwandder               $error_exit_code
    check_var task_wandio                   $error_exit_code
    check_var task_libtrace                 $error_exit_code
    check_var task_libtrace_tutorial        $error_exit_code
    #[ PARAM - EXECUTION MODE ] X 1
    check_var script_stat                   $error_exit_code
    #[ PARAM - PROGRAM FLAGS ] X 2
    check_var wget_flags                    $error_exit_code
    check_var tar_flags                     $error_exit_code
    #[ PARAM - PATHS & URLS ] X 14
    check_var this_script                   $error_exit_code
    check_var program_install_dir           $error_exit_code
    check_var system_include_dir            $error_exit_code
    check_var system_lib_dir                $error_exit_code
    check_var uthash_repo_url               $error_exit_code
    check_var uthash_name                   $error_exit_code
    check_var libwandder_release_url        $error_exit_code
    check_var libwandder_name               $error_exit_code
    check_var wandio_release_url            $error_exit_code
    check_var wandio_name                   $error_exit_code
    check_var libtrace_release_url          $error_exit_code
    check_var libtrace_name                 $error_exit_code
    check_var libtrace_turorial_repo_url    $error_exit_code
    check_var libtrace_tutorial_name        $error_exit_code

    if [ $verbose == 1 ]; then
        echo_notice "$message1" "$message2" "Performinng mutual actions"
    fi
    if [ $script_stat == "dev" ]; then
        :
    elif [ $script_stat == "prod" ]; then
        make_flags="-j$(nproc)"
    fi
    libwandder_file="${libwandder_name}-${libwandder_release_url##*/}"
    libwandder_ln="${libwandder_file//.tar.gz}"
    wandio_file="${wandio_name}-${wandio_release_url##*/}"
    wandio_ln="${wandio_file//.tar.gz}"
    libtrace_file="${libtrace_name}-${libtrace_release_url##*/}"
    libtrace_ln="${libtrace_file//.tar.gz}"
    current_dir=$(pwd)
}
if [ $verbose == 1 ]; then
    echo_notice "$message1" "$message2" "Loaded common functions"
fi
