#!/bin/bash
# functions.sh is required to be sourced before using functions in this file

# value: 1: verbose
verbose=0
message1="ACN_Code/hw4_libtrace_setup/common_functions.sh"
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

    if [ $verbose == 1 ]; then
        echo_notice "$message1" "$message2" "Checking variable values"
    fi
    #[ PARAM - TASKS ] X 5(skip)
    #[ PARAM - EXECUTION MODE ] X 1
    if [ $script_stat != "dev" ] && [ $script_stat != "prod" ]; then
        echo_error "$message1" "$message2" "Invalid script_stat: should be either dev or prod" $error_exit_code
    fi

    if [ $verbose == 1 ]; then
        echo_notice "$message1" "$message2" "Setting private variables"
    fi
    wget_flags="-nv --show-progress"
    tar_flags="-xzf"
    this_script="ACN_Code/hw4_libtrace_setup/setup.sh"
    program_install_dir="/opt"
    system_include_dir="/usr/local/include"
    system_lib_dir="/usr/local/lib"
    system_share_dir="/usr/local/share"
    uthash_repo_url="https://github.com/troydhanson/uthash.git"
    uthash_name="uthash"
    libwandder_release_url="https://github.com/LibtraceTeam/libwandder/archive/refs/tags/2.0.11-1.tar.gz"
    libwandder_name="libwandder"
    wandio_release_url="https://github.com/LibtraceTeam/wandio/archive/refs/tags/4.2.6-1.tar.gz"
    wandio_name="wandio"
    libtrace_release_url="https://github.com/LibtraceTeam/libtrace/archive/refs/tags/4.0.24-1.tar.gz"
    libtrace_name="libtrace"
    libtrace_turorial_repo_url="https://github.com/ylai/libtrace_tutorial.git"
    libtrace_tutorial_name="libtrace_tutorial"

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
