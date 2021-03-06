
S9S=$(which s9s)
FAILED="no"
TEST_SUITE_NAME=""
TEST_NAME=""
DONT_PRINT_TEST_MESSAGES=""
PRINT_COMMANDS=""

TERM_NORMAL="\033[0;39m"
TERM_BOLD="\033[1m"
XTERM_COLOR_RED="\033[0;31m"
XTERM_COLOR_GREEN="\033[0;32m"
XTERM_COLOR_ORANGE="\033[0;33m"
XTERM_COLOR_BLUE="\033[0;34m"
XTERM_COLOR_PURPLE="\033[0;35m"
XTERM_COLOR_CYAN="\033[0;36m"
XTERM_COLOR_LIGHT_GRAY="\033[0;37m"
XTERM_COLOR_DARK_GRAY="\033[1;30m"
XTERM_COLOR_LIGHT_RED="\033[1;31m"
XTERM_COLOR_LIGHT_GREEN="\033[1;32m"
XTERM_COLOR_YELLOW="\033[1;33m"
XTERM_COLOR_LIGHT_BLUE="\033[1;34m"
XTERM_COLOR_LIGHT_PURPLE="\033[1;35m"
XTERM_COLOR_LIGHT_CYAN="\033[1;36m"
XTERM_COLOR_WHITE="\033[1;37m"

if [ -x ../s9s/s9s ]; then
    S9S="../s9s/s9s"
fi

function color_command()
{
    sed \
        -e "s#\(--.\+\)=\([^\\]\+\)#\x1b\[0;33m\1\x1b\[0;39m=\x1b\[1;35m\2\x1b\[0;39m#g" \
        -e "s#\(--[^\\\ ]\+\)#\x1b\[0;33m\1\x1b\[0;39m#g"
}

function prompt_string
{
    local dirname=$(basename $PWD)

    echo "$USER@$HOSTNAME:$dirname\$"
}

function mys9s_singleline()
{
    local prompt=$(prompt_string)
    local nth=0

    if [ "$PRINT_COMMANDS" ]; then
        echo -ne "$prompt ${XTERM_COLOR_YELLOW}s9s${TERM_NORMAL} "

        for argument in "$@"; do
            #if [ $nth -gt 0 ]; then
            #    echo -e "\\"
            #fi

            if [ $nth -eq 0 ]; then
                echo -ne "${XTERM_COLOR_BLUE}$argument${TERM_NORMAL}"
            elif [ $nth -eq 1 ]; then
                echo -ne " ${XTERM_COLOR_ORANGE}$argument${TERM_NORMAL}"
            else
                echo -ne " $argument" | color_command
            fi

            let nth+=1
        done
    
        echo ""
    fi

    $S9S --color=always "$@"
}

function mys9s_multiline()
{
    local prompt=$(prompt_string)
    local nth=0

    if [ "$PRINT_COMMANDS" ]; then
        echo ""
        echo -ne "$prompt ${XTERM_COLOR_YELLOW}s9s${TERM_NORMAL} "

        for argument in "$@"; do
            if [ $nth -gt 0 ]; then
                echo -e "\\"
            fi

            if [ $nth -eq 0 ]; then
                echo -ne "${XTERM_COLOR_BLUE}$argument${TERM_NORMAL} "
            elif [ $nth -eq 1 ]; then
                echo -ne "    ${XTERM_COLOR_ORANGE}$argument${TERM_NORMAL} "
            else
                echo -ne "    $argument " | color_command
            fi

            let nth+=1
        done
    
        echo ""
        echo ""
    fi

    $S9S --color=always "$@"
}

function mys9s()
{
    local n_arguments=0
    local argument

    for argument in $*; do
        let n_arguments+=1
    done

    if [ "$n_arguments" -lt 4 ]; then
        mys9s_singleline "$@"
    else
        mys9s_multiline "$@"
    fi
}

#
# This function should be called before the functional tests are executed.
# Currently this only prints a message for the user, but this might change.
#
function startTests ()
{
    TEST_SUITE_NAME=$(basename $0 .sh)

    if [ -z "$DONT_PRINT_TEST_MESSAGES" ]; then
        echo ""
        echo "***********************"
        echo "* $TEST_SUITE_NAME"
        echo "***********************"
    fi
}

#
# This function should be called when the function tests are executed. It prints
# a message about the results and exits with the exit code that is true if the
# tests are passed and false if at least one test is failed.
#
function endTests ()
{
    if isSuccess; then
        if [ -z "$DONT_PRINT_TEST_MESSAGES" ]; then
            echo "SUCCESS: $(basename $0 .sh)"
        else
            print_title "Report"
            echo " Test $(basename $0) is successful."
        fi
          
        exit 0
    else
        if [ -z "$DONT_PRINT_TEST_MESSAGES" ]; then
            echo "FAILURE: $(basename $0 .sh)"
        else
            echo "Test $(basename $0) has failed."
        fi
    
        exit 1
    fi
}

#
# This is the BASH function that executes a functional test. The functional test
# itself should be implemented as a BASH function.
#
function runFunctionalTest ()
{
    TEST_NAME=$1

    if ! isSuccess; then
        if [ -z "$DONT_PRINT_TEST_MESSAGES" ]; then
            printf "  %-26s: SKIPPED\n" $1
        fi

        return 1
    else
        $1
    fi

    if [ -z "$DONT_PRINT_TEST_MESSAGES" ]; then
        if ! isSuccess; then
            printf "  %-26s: FAILURE\n" $1
        else 
            printf "  %-26s: SUCCESS\n" $1
        fi
    fi
}

#
# Returns true if none of the tests failed before, false if some bug was
# detected.
#
function isSuccess 
{
    if [ "$FAILED" == "no" ]; then
        return 0
    fi

    return 1
}

#
# Returns true if the --verbose option was provided.
#
function isVerbose 
{
    if [ "$VERBOSE" == "true" ]; then
        return 0
    fi

    return 1
}

#
# Prints the message passed as command line options if the test is executet in
# verbose mode (the --verbose command line option was provided).
#
function printVerbose 
{
    isVerbose && echo "$@" >&2
}

#
# Prints a message about the failure and sets the test failed state.
#
function failure
{
    if [ "$TEST_SUITE_NAME" -a "$TEST_NAME" ]; then
        echo "$TEST_SUITE_NAME::$TEST_NAME(): $1."
    else
        echo "FAILURE: $1"
    fi

    FAILED="true"
}

#
# This will check the exit code passed as an argument and print the logs
# of the last failed job if the exit code is not 0.
#
function check_exit_code()
{
    local exitCode="$1"
    local jobId

    if [ "$exitCode" -ne 0 ]; then
        failure "The exit code is ${exitCode}."

        jobId=$(\
            s9s job --list --batch | \
            grep FAIL | \
            tail -n1 | \
            awk '{print $1}')

        if [ "$jobId" ]; then
            mys9s job --log --debug --job-id="$jobId"
        fi

        exit $exitCode
    fi
}

function check_exit_code_no_job()
{
    local exitCode="$1"

    if [ "$exitCode" -ne 0 ]; then
        failure "The exit code is ${exitCode}."
    fi
}

#
# This function will check if a core file is created and fails the test if so.
#
function checkCoreFile 
{
    for corefile in data/core /tmp/cores/*; do 
        if [ -e "$corefile" ]; then
            failure "Some core file(s) found."
            ls -lha $corefile
        fi
    done
}

#
# $1: the file in which the output messages are stored.
# $2: the message to find.
#
function checkMessage()
{
    local file="$1"
    local message="$2"

    if [ -z "$file" ]; then
        failure "Internal error: checkMessage() has no file name"
        return 1
    fi

    if [ -z "$message" ]; then
        failure "Internal error: checkMessage() has no message"
        return 1
    fi

    if grep -q "$message" "$file"; then
        return 0
    fi

    failure "Text '$message' missing from output"
    return 1
}

#
# Prints an error message to the standard error. The text will not mixed up with
# the data that is printed to the standard output.
#
function printError()
{
    local datestring=$(date "+%Y-%m-%d %H:%M:%S")

    echo -e "$*" >&2

    if [ "$LOGFILE" ]; then
        echo -e "$datestring ERROR $MYNAME($$) $*" >>"$LOGFILE"
    fi
}


function cluster_state()
{
    local clusterId="$1"

    s9s cluster --list --cluster-id=$clusterId --cluster-format="%S"
}        

function node_state()
{
    local nodeName="$1"
        
    s9s node --list --batch --long --node-format="%S" "$nodeName"
}



#
# This function will wait for a node to pick up a state and stay in that state
# for a while.
#
function wait_for_node_state()
{
    local nodeName="$1"
    local expectedState="$2"
    local state
    local waited=0
    local stayed=0

    if [ -z "$nodeName" ]; then
        printError "Expected a node name."
        return 6
    fi

    if [ -z "$expectedState" ]; then 
        printError "Expected state name."
        return 6
    fi

    while true; do
        state=$(node_state "$nodeName")
        if [ "$state" == $expectedState ]; then
            let stayed+=1
        else
            let stayed=0

            #
            # Would be crazy to timeout when we are in the expected state, so we
            # do check the timeout only when we are not in the expected state.
            #
            if [ "$waited" -gt 120 ]; then
                return 1
            fi
        fi

        if [ "$stayed" -gt 10 ]; then
            return 0
        fi

        let waited+=1
        sleep 1
    done

    return 2
}

#
# This function waits until the host goes into CmonHostShutDown state and then
# waits if it remains in that state for a while. A timeout is implemented and 
# the return value shows if the node is indeed in the CmonHostShutDown state.
#
function wait_for_node_shut_down()
{
    wait_for_node_state "$1" "CmonHostShutDown"
    return $?
}

#
# This function waits until the host goes into CmonHostOnline state and then
# waits if it remains in that state for a while. A timeout is implemented and 
# the return value shows if the node is indeed in the CmonHostOnline state.
#
function wait_for_node_online()
{
    wait_for_node_state "$1" "CmonHostOnline"
    return $?
}

#
# This function waits until the host goes into CmonHostOffLine state and then
# waits if it remains in that state for a while. A timeout is implemented and 
# the return value shows if the node is indeed in the CmonHostOffLine state.
#
function wait_for_node_offline()
{
    wait_for_node_state "$1" "CmonHostOffLine"
    return $?
}

#
# This function waits until the host goes into CmonHostFailed state and then
# waits if it remains in that state for a while. A timeout is implemented and 
# the return value shows if the node is indeed in the CmonHostFailed state.
#
function wait_for_node_failed()
{
    wait_for_node_state "$1" "CmonHostFailed"
    return $?
}

function wait_for_cluster_state()
{
    local clusterName="$1"
    local expectedState="$2"
    local state
    local waited=0
    local stayed=0

    if [ -z "$clusterName" ]; then
        printError "Expected a cluster name."
        return 6
    fi

    if [ -z "$expectedState" ]; then 
        printError "Expected state name."
        return 6
    fi

    while true; do
        state=$(s9s cluster \
            --list \
            --cluster-format="%S" \
            --cluster-name="$clusterName")

        if [ "$state" == $expectedState ]; then
            let stayed+=1
        else
            let stayed=0

            #
            # Would be crazy to timeout when we are in the expected state, so we
            # do check the timeout only when we are not in the expected state.
            #
            if [ "$waited" -gt 120 ]; then
                return 1
            fi
        fi

        if [ "$stayed" -gt 10 ]; then
            return 0
        fi

        let waited+=1
        sleep 1
    done

    return 2
}

function wait_for_cluster_started()
{
    wait_for_cluster_state "$1" "STARTED"
    return $?
}


#
# $1: the server name
#
function is_server_running_ssh()
{
    local serverName="$1"
    local owner="$2"
    local isOK

    isOk=$(sudo -u $owner -- ssh -o ConnectTimeout=1 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=quiet "$serverName" 2>/dev/null -- echo OK)
    if [ "$isOk" == "OK" ]; then
        return 0
    fi

    return 1
}

#
# $2: the server name
#
# Waits until the server is accepting SSH connections. There is also a timeout
# implemented here.
#
function wait_for_server_ssh()
{
    local serverName="$1"
    local OWNER="$2"
    local nTry=0
    local nSuccess=0

    while true; do
        if is_server_running_ssh "$serverName" $OWNER; then
            printVerbose "Server '$serverName' is reachable."
            let nSuccess+=1
        else
            printVerbose "Server '$serverName' is not reachable."
            let nSuccess=0

            # 120 x 5 = 10 minutes
            if [ "$nTry" -gt 180 ]; then
                printVerbose "Server '$serverName' did not came alive."
                return 1
            fi
        fi

        if [ "$nSuccess" -gt 3 ]; then
            printVerbose "Server '$serverName' is stable."
            return 0
        fi

        sleep 5
        let nTry+=1
    done

    return 0
}

#
# $1: The name of the container or just leave it empty for the default name.
#
# Creates and starts a new virtual machine node.
#
function create_node()
{
    local ip
    local retval
    local verbose_option=""

    if [ "$VERBOSE" ]; then
        verbose_option="--verbose"
    fi

    if [ -z "$CONTAINER_SERVER" ]; then
        printError "The container server is not set."
        return 1
    fi

    printVerbose "Creating container..."
    ip=$(pip-container-create $verbose_option --server=$CONTAINER_SERVER $1)
    printVerbose "Created '$ip'."
   
    #
    # Waiting until the server is up and accepts SSH connections.
    #
    wait_for_server_ssh "$ip" "$USER"
    retval=$?
    if [ "$retval" -ne 0 ]; then
        echo "Could not reach created server at ip '$ip'." >&2
    fi

    echo $ip
}

function emit_s9s_configuration_file()
{
    cat <<EOF
#
# This configuration file was created by ${MYNAME} version ${VERSION}.
#
[global]
controller = https://localhost:9556

[log]
brief_job_log_format = "%36B:%-5L: %-7S %M\n"
brief_log_format     = "%C %36B:%-5L: %-8S %M\n"
EOF
}

function reset_config()
{
    local config_dir="$HOME/.s9s"
    local config_file="$config_dir/s9s.conf"

    if [ -z "$OPTION_RESET_CONFIG" ]; then
        return 0
    fi
    
    print_title "Overwriting s9s Configuration"

    if [ -d "$config_file" ]; then
        rm -rf "$config_file"
    fi

    if [ ! -d "$config_dir" ]; then
        mkdir "$config_dir"
    fi

    emit_s9s_configuration_file >$config_file

    # This goes to the standard output.
    emit_s9s_configuration_file
}

#
# $1: the name of the cluster
#
function find_cluster_id()
{
    local name="$1"
    local retval
    local nTry=0

    while true; do
        retval=$($S9S cluster --list --long --batch --cluster-name="$name")
        retval=$(echo "$retval" | awk '{print $1}')

        if [ -z "$retval" ]; then
            printVerbose "Cluster '$name' was not found."
            let nTry+=1

            if [ "$nTry" -gt 10 ]; then
                echo "NOT-FOUND"
                break
            else
                sleep 3
            fi
        else
            printVerbose "Cluster '$name' was found with ID ${retval}."
            echo "$retval"
            break
        fi
    done
}

#
# Just a normal createUser call we do all the time to register a user on the
# controller so that we can actually execute RPC calls.
#
function grant_user()
{
    local first
    local last

    print_title "Creating first user"
    first=$(getent passwd $USER | cut -d ':' -f 5 | cut -d ',' -f 1 | cut -d ' ' -f 1)
    last=$(getent passwd $USER | cut -d ':' -f 5 | cut -d ',' -f 1 | cut -d ' ' -f 2)

    mys9s user \
        --create \
        --group="testgroup" \
        --create-group \
        --generate-key \
        --controller="https://localhost:9556" \
        --new-password="p" \
        --email-address="laszlo@severalnines.com" \
        --first-name="$first" \
        --last-name="$last" \
        $OPTION_PRINT_JSON \
        $OPTION_VERBOSE \
        --batch \
        "$USER"

    exitCode=$?
    if [ "$exitCode" -ne 0 ]; then
        failure "Exit code is not 0 while granting user."
        return 1
    fi

    #
    # Adding the user's default SSH public key. This will come handy when we
    # create a container because this way the user will be able to log in with
    # the SSH key without password.
    #
    mys9s user \
        --add-key \
        --public-key-file="/home/$USER/.ssh/id_rsa.pub" \
        --public-key-name="The SSH key"

    #mys9s user --list-keys
}


function print_title()
{
    echo ""
    echo -e "\033[1m$*\033[0;39m"
    echo -e "\033[1m\
-------------------------------------------------------------------------------\
-\033[0;39m"
}


#
# This will destroy the containers we created.
#
function destroyNodes()
{
    if [ "$OPTION_INSTALL" ]; then
        print_title "Leaving the containers"
        echo "The --install option was provided, not destroying the "
        echo "containers."
        echo "     server : $CONTAINER_SERVER"
        echo " containers : $ALL_CREATED_IPS"
        return 0
    fi

    if [ "$ALL_CREATED_IPS" ]; then
        print_title "Destroying the containers"
        echo "     server : $CONTAINER_SERVER"
        echo " containers : $ALL_CREATED_IPS"

        pip-container-destroy \
            --server=$CONTAINER_SERVER \
            "$ALL_CREATED_IPS" \
            >/dev/null 2>/dev/null
        
        echo "    retcode : $?"

        ALL_CREATED_IPS=""
    fi

    return 0
}

trap destroyNodes EXIT

