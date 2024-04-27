#!/bin/bash
#
# Clone instead of repo but release if possible
# Version check rely on automake
# Network activities are put in the front section
# Script will terminate once error occurs

# ====================================================================================
# Init
# ====================================================================================
bash_function_url="https://raw.githubusercontent.com/belongtothenight/bash_scripts/main/src/functions.sh"
bash_function_file="./functions.sh"

echo "Installing mutual dependencies"
sudo apt install -y build-essential git wget || { echo 'apt failed' ; exit 1; }

echo "Downloading bash functions"
sudo wget -nv --show-progress ${bash_function_url} --output-document ${bash_function_file} || { echo 'wget failed'; exit 1; }

echo "Sourcing bash functions"
source "${bash_function_file}" || { echo 'source failed'; exit 1; } # Enter fail-exit mode
source "./common_functions.sh"
load_preset "./config.ini"

# ====================================================================================
# Download source code
# ====================================================================================
if [ $task_uthash == 1 ]; then
    echo_notice "$this_script" "base" "Cloning uthash repo"
    if [ $script_stat == "dev" ]; then
        err_conti_exec "sudo git clone ${uthash_repo_url} ${program_install_dir}/${uthash_name}" "${this_script}" "base"
    elif [ $script_stat == "prod" ]; then
        err_retry_exec "sudo git clone ${uthash_repo_url} ${program_install_dir}/${uthash_name}" 1 5 "${this_script}" "base" 1
    fi
fi

if [ $task_libwandder == 1 ]; then
    echo_notice "$this_script" "base" "Downloading libwandder release"
    if [ $script_stat == "dev" ]; then
        err_conti_exec "sudo wget $wget_flags --output-document ${program_install_dir}/${libwandder_file} ${libwandder_release_url}" "${this_script}" "base"
    elif [ $script_stat == "prod" ]; then
        err_retry_exec "sudo wget $wget_flags --output-document ${program_install_dir}/${libwandder_file} ${libwandder_release_url}" 1 5 "${this_script}" "base" 1
    fi
fi

if [ $task_wandio == 1 ]; then
    echo_notice "$this_script" "base" "Downloading wandio release"
    if [ $script_stat == "dev" ]; then
        err_conti_exec "sudo wget $wget_flags --output-document ${program_install_dir}/${wandio_file} ${wandio_release_url}" "${this_script}" "base"
    elif [ $script_stat == "prod" ]; then
        err_retry_exec "sudo wget $wget_flags --output-document ${program_install_dir}/${wandio_file} ${wandio_release_url}" 1 5 "${this_script}" "base" 1
    fi
fi

if [ $task_libtrace == 1 ]; then
    echo_notice "$this_script" "base" "Cloning libtrace repo"
    if [ $script_stat == "dev" ]; then
        err_conti_exec "sudo wget $wget_flags --output-document ${program_install_dir}/${libtrace_file} ${libtrace_release_url}" "${this_script}" "base"
    elif [ $script_stat == "prod" ]; then
        err_retry_exec "sudo wget $wget_flags --output-document ${program_install_dir}/${libtrace_file} ${libtrace_release_url}" 1 5 "${this_script}" "base" 1
    fi
fi

if [ $task_libtrace_tutorial == 1 ]; then
    echo_notice "$this_script" "base" "Cloning libtrace tutorial repo"
    if [ $script_stat == "dev" ]; then
        err_conti_exec "sudo git clone ${libtrace_turorial_repo_url} ${program_install_dir}/libtrace_tutorial" "${this_script}" "base"
    elif [ $script_stat == "prod" ]; then
        err_retry_exec "sudo git clone ${libtrace_turorial_repo_url} ${program_install_dir}/libtrace_tutorial" 1 5 "${this_script}" "base" 1
    fi
fi

# ====================================================================================
# Install dependencies with dpkg
# ====================================================================================
if [ $task_wandio == 1 ]; then
    echo_notice "$this_script" "base" "Installing wandio dependencies"
    if [ $script_stat == "dev" ]; then
        :
    elif [ $script_stat == "prod" ]; then
        err_retry_exec "aptins automake"                1 5 "${this_script}" "base" 1 # >= 1.9
        err_retry_exec "aptins libpthread-stubs0-dev"   1 5 "${this_script}" "base" 1 # (optional)
        err_retry_exec "aptins zlib1g-dev"              1 5 "${this_script}" "base" 1 # (optional)
        err_retry_exec "aptins libbz2-dev"              1 5 "${this_script}" "base" 1 # (optional)
        err_retry_exec "aptins liblzma-dev"             1 5 "${this_script}" "base" 1 # (optional)
        err_retry_exec "aptins liblzo2-dev"             1 5 "${this_script}" "base" 1 # (optional)
        err_retry_exec "aptins liblz4-dev"              1 5 "${this_script}" "base" 1 # (optional)
        err_retry_exec "aptins libzstd-dev"             1 5 "${this_script}" "base" 1 # (optional)
    fi
fi

if [ $task_libtrace == 1 ]; then
    echo_notice "$this_script" "base" "Installing libtrace dependencies"
    if [ $script_stat == "dev" ]; then
        :
    elif [ $script_stat == "prod" ]; then
        err_retry_exec "aptins automake"                1 5 "${this_script}" "base" 1 # >= 1.9, done
        err_retry_exec "aptins libpcap-dev"             1 5 "${this_script}" "base" 1 # >= 0.8
        err_retry_exec "aptins flex"                    1 5 "${this_script}" "base" 1
        err_retry_exec "aptins bison"                   1 5 "${this_script}" "base" 1
        err_retry_exec "aptins pkg-config"              1 5 "${this_script}" "base" 1
        #err_retry_exec "aptins libwandio-dev"           1 5 "${this_script}" "base" 1 # build from source
        err_retry_exec "aptins libyaml-dev"             1 5 "${this_script}" "base" 1 # (optional)
        err_retry_exec "aptins libssl-dev"              1 5 "${this_script}" "base" 1 # (optional) for libcrypto
        err_retry_exec "aptins libncurses5-dev"         1 5 "${this_script}" "base" 1 # (optional) for libncurses
        err_retry_exec "aptins libncursesw5-dev"        1 5 "${this_script}" "base" 1 # (optional) for libncurses
    else
        echo_error "$this_script" "base" "Unknown script_stat"
        exit 1
    fi
fi

# ====================================================================================
# Source code preparation
# ====================================================================================
if [ $task_libwandder == 1 ] || [ $task_wandio == 1 ] || [ $task_libtrace == 1 ]; then
    echo_notice "$this_script" "base" "Extracting .tar.gz files"
    if [ $task_libwandder == 1 ]; then
        sudo tar $tar_flags "${program_install_dir}/${libwandder_file}" -C "${program_install_dir}"
    fi
    if [ $task_wandio == 1 ]; then
        sudo tar $tar_flags "${program_install_dir}/${wandio_file}" -C "${program_install_dir}"
    fi
    if [ $task_libtrace == 1 ]; then
        sudo tar $tar_flags "${program_install_dir}/${libtrace_file}" -C "${program_install_dir}"
    fi
    echo_notice "$this_script" "base" "Creating symbolic links"
    if [ $task_libwandder == 1 ]; then
        if [ $script_stat == "dev" ]; then
            err_conti_exec "sudo ln -s ${program_install_dir}/${libwandder_ln} ${program_install_dir}/${libwandder_name}" "${this_script}" "base"
        elif [ $script_stat == "prod" ]; then
            sudo ln -s "${program_install_dir}/${libwandder_ln}" "${program_install_dir}/${libwandder_name}"
        else
            echo_error "$this_script" "base" "Unknown script_stat"
            exit 1
        fi
    fi
    if [ $task_wandio == 1 ]; then
        if [ $script_stat == "dev" ]; then
            err_conti_exec "sudo ln -s ${program_install_dir}/${wandio_ln} ${program_install_dir}/${wandio_name}" "${this_script}" "base"
        elif [ $script_stat == "prod" ]; then
            sudo ln -s "${program_install_dir}/${wandio_ln}" "${program_install_dir}/${wandio_name}"
        else
            echo_error "$this_script" "base" "Unknown script_stat"
            exit 1
        fi
    fi
    if [ $task_libtrace == 1 ]; then
        if [ $script_stat == "dev" ]; then
            err_conti_exec "sudo ln -s ${program_install_dir}/${libtrace_ln} ${program_install_dir}/${libtrace_name}" "${this_script}" "base"
        elif [ $script_stat == "prod" ]; then
            sudo ln -s "${program_install_dir}/${libtrace_ln}" "${program_install_dir}/${libtrace_name}"
        else
            echo_error "$this_script" "base" "Unknown script_stat"
            exit 1
        fi
    fi
fi

# ====================================================================================
# Building & Installing
# ====================================================================================
if [ $task_uthash == 1 ]; then
    echo_notice "$this_script" "base" "Copying uthash headers to system include path"
    sudo cp ${program_install_dir}/${uthash_name}/src/* "${system_include_dir}"
fi

if [ $task_libwandder == 1 ]; then
    echo_notice "$this_script" "base" "Building libwandder"
    cd "${program_install_dir}/${libwandder_name}"
    sudo ./bootstrap.sh
    sudo ./configure
    sudo make $make_flags
    sudo make install $make_flags
fi

if [ $task_wandio == 1 ]; then
    echo_notice "$this_script" "base" "Building wandio"
    cd "${program_install_dir}/${wandio_name}"
    sudo ./bootstrap.sh
    sudo ./configure
    sudo make $make_flags
    sudo make install $make_flags
fi

if [ $task_libtrace == 1 ]; then
    echo_notice "$this_script" "base" "Building libtrace"
    cd "${program_install_dir}/${libtrace_name}"
    sudo ./bootstrap.sh
    sudo ./configure LDFLAGS=-L/usr/local/lib CPPFLAGS=-I/usr/local/include
    sudo make $make_flags
    sudo make install $make_flags
fi

if [ $task_libtrace_tutorial == 1 ]; then
    echo_notice "$this_script" "base" "Building libtrace tutorial"
    libtrace_tutorial_lib_massdal="${program_install_dir}/${libtrace_tutorial_name}/lib/massdal"
    libtrace_tutorial_hw0="${program_install_dir}/${libtrace_tutorial_name}/hw0"
    libtrace_tutorial_codedemo="${program_install_dir}/${libtrace_tutorial_name}/codedemo"
    #LD_LIBRARY_PATH="${program_install_dir}/${libwandder_name}/src:${program_install_dir}/${wandio_name}/src"
    LD_LIBRARY_PATH="${system_lib_dir}:${system_include_dir}:${libtrace_tutorial_lib_massdal}:$LD_LIBRARY_PATH"
    echo_notice "$this_script" "base" "Building libtrace tutorial -> lib/massdal"
    cd $libtrace_tutorial_lib_massdal
    sudo make $make_flags
    echo_notice "$this_script" "base" "Building libtrace tutorial -> hw0"
    cd $libtrace_tutorial_hw0
    sudo make $make_flags
    echo_notice "$this_script" "base" "Building libtrace tutorial -> codedemo"
    cd $libtrace_tutorial_codedemo
    sudo make $make_flags
fi

# End of file
echo_notice "$this_script" "base" "Setup complete"
