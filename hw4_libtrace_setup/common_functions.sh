#!/bin/bash
# functions.sh is required to be sourced before using functions in this file

# value: 1: verbose
verbose=0
message1="ACN_Code/hw4_libtrace_setup/common_functions.sh"
message2="base"
error_exit_code=1

file_name=$(realpath "$0")
dir_name=$(dirname "$file_name")

# ==============================================================================
# Following functions are copied from https://github.com/belongtothenight/bash_scripts/blob/main/src/functions.sh
# Do so to minimize dependency to further decrease points of failure
# ==============================================================================

# Function: load terminal special characters
# Usage: load_special_chars
# No input variable
load_special_chars () {
    readonly BOLD="\033[1m"
    readonly BLUE="\033[34m"
    readonly RED="\033[31m"
    readonly GREEN="\033[32m"
    readonly YELLOW="\033[33m"
    readonly END="\033[0m"
    readonly CLEAR_LINE="\033[2K"
}
load_special_chars
if [ $verbose == 1 ]; then
    echo -e "${BOLD}${BLUE}[NOTICE-${dir_name}/${file_name}]${END} Loaded and Activated function: load_special_chars"
fi

# Function: error handling
# Usage: Add the following lines to the beginning of the script
# 1. set -eE -o functrace
# 2. trap 'failure "$LINENO" "$BASH_COMMAND" "$FUNCNAME" "$BASH_SOURCE"' ERR
# Source: https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
set -eE -o functrace # need to be just before trap (this location)
failure () {
    local line_no=$1
    local bash_cmd=$2
    local bash_fun=$3
    local bash_src=$4
    echo_error "common" "function" "Error: source: $BOLD$bash_src$END, $BOLD$bash_fun$END has failed at line $BOLD$line_no$END, command: $BOLD$bash_cmd$END" 1
}
trap 'failure "$LINENO" "$BASH_COMMAND" "$FUNCNAME" "$BASH_SOURCE"' ERR
if [ $verbose == 1 ]; then
    echo_notice "common" "function" "Loaded and Activated function: failure"
fi

# Function: notice message
# Usage: echo_notice "filename" "unit" "message"
# Input variable: $1: filename
#                 $2: unit
#                 $3: message
echo_notice () {
    echo -e "${BOLD}${BLUE}[NOTICE-$1/$2]${END} $3"
}
if [ $verbose == 1 ]; then
    echo_notice "common" "function" "Loaded function: echo_notice"
fi

# Function: error message
# Usage: echo_error "filename" "unit" "message" "exit code"
# Input variable: $1: filename
#                 $2: unit
#                 $3: message
#                 $4: exit code
echo_error () {
    echo -e "${BOLD}${RED}[ERROR-$1/$2]${END} $3"
    exit $4
}
if [ $verbose == 1 ]; then
    echo_notice "common" "function" "Loaded function: echo_error"
fi

# Function: continue execution when error occurs
# Usage: err_conti_exec "command string" "message 1" "message 2"
# Input variable: $1: command string (ex: "sudo apt update && echo "update done")
#                 $2: message 1
#                 $3: message 2
err_conti_exec () {
    $1 || echo_warn "$2" "$3" "Warning: \"$1\" failed, but continue execution..."
}
if [ $verbose == 1 ]; then
    echo_notice "common" "function" "Loaded and Activated function: err_conti_exec"
fi

# Function: retry execution when error occurs
# Usage: err_retry_exec "command string" "interval in second" "retry times" "message 1" "message 2" "exit code
# Input variable: $1: command string (ex: "sudo apt update && echo "update done")
#                 $2: interval in second (ex: 5, true to skip interval)
#                 $3: retry times (ex: 3)
#                 $4: message 1
#                 $5: message 2
#                 $6: exit code
err_retry_exec () {
    local retry_cnt=0
    until
        $1
    do
        retry_cnt=$((retry_cnt+1))
        if [ $retry_cnt -eq $3 ]; then
            echo_error "$4" "$5" "Error: \"$1\" failed after $3 retries" $6
        fi
        echo_warn "$4" "$5" "Warning: \"$1\" failed, retrying in $2 seconds..."
        sleep $2
    done
}
if [ $verbose == 1 ]; then
    echo_notice "common" "function" "Loaded and Activated function: err_retry_exec"
fi

# Function: install package with apt
# Usage: aptins "package name"
# $1: package name
aptins () {
    echo_notice "common" "setup" "Installing ${BOLD}${GREEN}$1${END}..."
    err_retry_exec "sudo apt -q -o DPkg::Lock::Timeout=300 install $1 -y" 1 5 "common" "functions_aptins" 1
}
if [ $verbose == 1 ]; then
    echo_notice "common" "function" "Loaded function: aptins"
fi

# Function: check variable is empty and exit if empty
# Usage check_var "variable" "exit code"
# $1: variable
# $2: exit code
check_var () {
    if [ -z "${!1}" ]; then
        echo_error "common" "function" "Error: variable $1 is empty! Check your config.ini file." $2
    fi
}
if [ $verbose == 1 ]; then
    echo_notice "common" "function" "Loaded function: check_var"
fi

# Function: parse config file
# Usage: parse "config.ini"
# Input variable: $1: config filepath
#                 $2: "display" display config item
parse () {
    var_cnt=0
    while read -r k e v; do
        if [[ $k == \#* ]]; then
            continue
        fi
        if [[ $k == "" ]]; then
            continue
        fi
        if [[ $k == "["* ]]; then
            continue
        fi
        if [[ $e != "=" ]]; then
            echo_error "common" "function" "Invalid config item, valid config item should be like this: <key> = <value>" 1
            continue
        fi
        if [[ $v == "" ]]; then
            echo_error "common" "function" "Error: $k is empty, Valid config item should be like this: <key> = <value>" 1
            continue
        fi
        if [ -z "${!k}" ]; then
            :
        else
            echo_warn "common" "function" "Warning: $k is already set, will not overwrite it"
            continue
        fi
        #declare "$k"="$v" # This is not working in function
        #readonly "$k"="$v" # Can't be easily unset
        eval "$k"='$v'
        var_cnt=$((var_cnt+1))
        if [[ $2 == "display" ]]; then
            echo "Loaded config item: $k = $v"
        fi
    done < "$1"
    echo_notice "common" "function" "Loaded ${BOLD}${GREEN}$var_cnt${END} config items from ${BOLD}${GREEN}$1${END}"
}
if [ $verbose == 1 ]; then
    echo_notice "common" "function" "Loaded function: parse"
fi

# ==============================================================================
# Following function is set for this script
# ==============================================================================

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
    check_var task_acn_code                 $error_exit_code
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
    unzip_flags="-q -u"
    this_script="ACN_Code/hw4_libtrace_setup/setup.sh"
    program_install_dir="/opt"
    system_include_dir="/usr/local/include"
    system_lib_dir="/usr/local/lib"
    system_bin_dir="/usr/local/bin"
    system_share_dir="/usr/local/share"
    uthash_zip_url="https://github.com/troydhanson/uthash/archive/refs/heads/master.zip"
    uthash_name="uthash"
    libwandder_release_url="https://github.com/LibtraceTeam/libwandder/archive/refs/tags/2.0.11-1.tar.gz"
    libwandder_name="libwandder"
    wandio_release_url="https://github.com/LibtraceTeam/wandio/archive/refs/tags/4.2.6-1.tar.gz"
    wandio_name="wandio"
    libtrace_release_url="https://github.com/LibtraceTeam/libtrace/archive/refs/tags/4.0.24-1.tar.gz"
    libtrace_name="libtrace"
    libtrace_tutorial_zip_url="https://github.com/ylai/libtrace_tutorial/archive/refs/heads/master.zip"
    libtrace_tutorial_name="libtrace_tutorial"
    acn_code_zip_url="https://github.com/belongtothenight/ACN_Code/archive/refs/heads/main.zip"
    acn_code_name="ACN_Code"

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
