#! /bin/bash
MYNAME=$(basename $0)
MYBASENAME=$(basename $0 .sh)
MYDIR=$(dirname $0)
STDOUT_FILE=ft_errors_stdout
VERBOSE=""
LOG_OPTION="--wait"
CLUSTER_NAME="${MYBASENAME}_$$"
CLUSTER_ID=""
ALL_CREATED_IPS=""
CONTAINER_SERVER=""

# The IP of the node we added first and last. Empty if we did not.
FIRST_ADDED_NODE=""
LAST_ADDED_NODE=""

cd $MYDIR
source include.sh

#
# Prints usage information and exits.
#
function printHelpAndExit()
{
cat << EOF
Usage: $MYNAME [OPTION]... [TESTNAME]
 Test script for s9s to check various error conditions.

 -h, --help       Print this help and exit.
 --verbose        Print more messages.
 --print-json     Print the JSON messages sent and received.
 --log            Print the logs while waiting for the job to be ended.
 --print-commands Do not print unit test info, print the executed commands.
 --reset-config   Remove and re-generate the ~/.s9s directory.
 --server=SERVER  Use the given server to create containers.

EOF
    exit 1
}

ARGS=$(\
    getopt -o h \
        -l "help,verbose,print-json,log,print-commands,reset-config,server:" \
        -- "$@")

if [ $? -ne 0 ]; then
    exit 6
fi

eval set -- "$ARGS"
while true; do
    case "$1" in
        -h|--help)
            shift
            printHelpAndExit
            ;;

        --verbose)
            shift
            VERBOSE="true"
            ;;

        --log)
            shift
            LOG_OPTION="--log"
            ;;

        --print-json)
            shift
            OPTION_PRINT_JSON="--print-json"
            ;;

        --print-commands)
            shift
            DONT_PRINT_TEST_MESSAGES="true"
            PRINT_COMMANDS="true"
            ;;

        --reset-config)
            shift
            OPTION_RESET_CONFIG="true"
            ;;

        --server)
            shift
            CONTAINER_SERVER="$1"
            shift
            ;;

        --)
            shift
            break
            ;;
    esac
done

if [ -z "$S9S" ]; then
    echo "The s9s program is not installed."
    exit 7
fi

#CLUSTER_ID=$($S9S cluster --list --long --batch | awk '{print $1}')

reset_config


if [ -z $(which pip-container-create) ]; then
    printError "The 'pip-container-create' program is not found."
    printError "Don't know how to create nodes, giving up."
    exit 1
fi

#
# Converts the date to a format the s9s program understands.
#
function dateFormat()
{
    TZ=GMT date -d "$1" "+%Y-%m-%dT%H:%M:%S.000Z"
}

#
#
#
function testPing()
{
    print_title "Pinging controller."

    #
    # Pinging. 
    #
    mys9s cluster --ping 

    exitCode=$?
    printVerbose "exitCode = $exitCode"
    if [ "$exitCode" -ne 0 ]; then
        failure "Exit code is not 0 while pinging controller."
        pip-say "The controller is off line. Further testing is not possible."
    else
        pip-say "The controller is on line."
    fi
}

#
# This test will allocate a few nodes and install a new cluster.
#
function testCreateCluster()
{
    local nodes
    local nodeName
    local exitCode

    print_title "Creating a cluster"

    nodeName=$(create_node)
    nodes+="$nodeName;"
    FIRST_NODENAME="$nodeName"
    ALL_CREATED_IPS+=" $nodeName"
    
    #
    # Creating a PostgreSQL cluster.
    #
    mys9s cluster \
        --create \
        --cluster-type=postgresql \
        --nodes="$nodes" \
        --cluster-name="$CLUSTER_NAME" \
        --db-admin="postmaster" \
        --db-admin-passwd="passwd12" \
        --provider-version="9.3" \
        $LOG_OPTION

    exitCode=$?
    printVerbose "exitCode = $exitCode"
    if [ "$exitCode" -ne 0 ]; then
        failure "Exit code is not 0 while creating cluster."
    fi

    CLUSTER_ID=$(find_cluster_id $CLUSTER_NAME)
    if [ "$CLUSTER_ID" -gt 0 ]; then
        printVerbose "Cluster ID is $CLUSTER_ID"
    else
        failure "Cluster ID '$CLUSTER_ID' is invalid"
    fi
}

#
# This test will create a maintenance and it waits until the maintenance is
# expired. Then the test checks if the maintenance period disappeared.
#
function testCreateMaintenance()
{
    local reason="test_$$_maintenance"

    print_title "Creating maintenance expiration"

    #
    # Creating a maintenance period that expires real soon.
    #
    mys9s maintenance \
        --create \
        --nodes=$FIRST_NODENAME \
        --start="$(dateFormat "now")" \
        --end="$(dateFormat "now + 10 sec")" \
        --reason="$reason" 
    
    exitCode=$?
    printVerbose "exitCode = $exitCode"
    if [ "$exitCode" -ne 0 ]; then
        failure "Exit code is not 0 while creating maintenance."
    fi
    
    #
    # The maintenance period should be there now.
    #
    printVerbose "Maintenance immediately:"
    mys9s maintenance --list --long

    if ! s9s maintenance --list --long | grep --quiet "$reason"; then
        failure "The maintenance not found with reason '$reason'."
    fi

    #
    # But it should disappear in a jiffy.
    #
    sleep 15
    printVerbose "After 15 seconds '$(date)':"
    mys9s maintenance --list --long

    if s9s maintenance --list --long | grep --quiet "$reason"; then
        failure "The maintenance should have expired: '$reason'."
    fi

    return 0
}

function testCreateTwoPeriods()
{
    print_title "Testing overlapping maintenance periods"

    #
    # Creating a maintenance period that expires real soon and an other one that
    # expires a bit later.
    #
    mys9s maintenance \
        --create \
        --nodes=$FIRST_NODENAME \
        --start="$(dateFormat "now")" \
        --end="$(dateFormat "now + 1 min")" \
        --reason="longer_$$" \
        --batch

    mys9s maintenance \
        --create \
        --nodes=$FIRST_NODENAME \
        --start="$(dateFormat "now")" \
        --end="$(dateFormat "now + 10 sec")" \
        --reason="shorter_$$" \
        --batch
    
    exitCode=$?
    printVerbose "exitCode = $exitCode"
    if [ "$exitCode" -ne 0 ]; then
        failure "Exit code is not 0 while creating cluster."
    fi

    #
    # The maintenance periods should be there now.
    #
    #printVerbose "Maintenance immediately:"
    #s9s maintenance --list --long
    if ! s9s maintenance --list --long | grep --quiet "shorter"; then
        failure "The shorter maintenance was not found."
    fi
    
    if ! s9s maintenance --list --long | grep --quiet "longer"; then
        failure "The longer maintenance was not found."
    fi

    #
    # But the short one should disappear in a jiffy.
    #
    sleep 15
    #printVerbose "After 15 seconds:"
    #s9s maintenance --list --long --batch
    if s9s maintenance --list --long | grep --quiet "shorter"; then
        failure "The shorter maintenance is still found."
    fi
    
    if ! s9s maintenance --list --long | grep --quiet "longer"; then
        failure "The longer maintenance was not found."
    fi

    return 0
}

#
# This will go and delete all the maintenance periods.
#
function testDeletePeriods()
{
    #
    # Creating maintenance periods.
    #
    print_title "Testing deleting of maintenance"

    mys9s \
        maintenance --create \
        --nodes=$FIRST_NODENAME \
        --start="$(dateFormat "now")" \
        --end="$(dateFormat "now + 1 day")" \
        --reason="test_1_$$" \
        --batch
    
    exitCode=$?
    printVerbose "exitCode = $exitCode"
    if [ "$exitCode" -ne 0 ]; then
        failure "Exit code is not 0 while creating maintenance."
    fi

    mys9s \
        maintenance --create \
        --nodes=$FIRST_NODENAME \
        --start="$(dateFormat "now")" \
        --end="$(dateFormat "now + 1 day")" \
        --reason="test_2_$$" \
        --batch
    
    exitCode=$?
    printVerbose "exitCode = $exitCode"
    if [ "$exitCode" -ne 0 ]; then
        failure "Exit code is not 0 while creating maintenance."
    fi
    
    mys9s \
        maintenance --create \
        --nodes=$FIRST_NODENAME \
        --start="$(dateFormat "now + 1 day")" \
        --end="$(dateFormat "now + 2 days")" \
        --reason="test_3_$$" \
        --batch
    
    exitCode=$?
    printVerbose "exitCode = $exitCode"
    if [ "$exitCode" -ne 0 ]; then
        failure "Exit code is not 0 while creating maintenance."
    fi

    #
    # The maintenance periods should be there now, so we can remove them.
    #
    #printVerbose "Maintenance immediately:"
    mys9s maintenance --list --long
    
    for uuid in $(s9s maintenance --list --batch); do
        mys9s maintenance --delete --uuid=$uuid --batch 
        if [ "$exitCode" -ne 0 ]; then
            failure "Exit code is not 0 while removing maintenance."
        fi
    done

    n_maintenances=$(s9s maintenance --list --batch | wc -l)
    if [ "$n_maintenances" -ne 0 ]; then
        failure "There are $n_maintenances remains after the delete."
    fi

    mys9s maintenance --list --long

    return 0
}

#
# This test will create a cluster maintenance then wait until it disappears. 
#
function testClusterMaintenance()
{
    local reason="cluster_maintenance_$$"

    
    #
    # Creating a maintenance period that expires real soon.
    #
    print_title "Creating a maintenance period that expires real soon"
    mys9s \
        maintenance --create \
        --cluster-id=$CLUSTER_ID \
        --start="$(dateFormat "now")" \
        --end="$(dateFormat "now + 5 seconds")" \
        --reason="$reason" \
        --batch
 
    exitCode=$?
    printVerbose "exitCode = $exitCode"
    if [ "$exitCode" -ne 0 ]; then
        failure "Exit code is not 0 while creating maintenance."
    fi

    #
    # The maintenance periods should be there now.
    #
    #printVerbose "Maintenance immediately:"
    mys9s maintenance --list --long

    if ! s9s maintenance --list --long | grep --quiet "$reason"; then
        failure "The maintenance not found: '$reason'."
    fi
   
    #
    # And should disappear in a few seconds.
    #
    sleep 10
    #printVerbose "After 15 seconds:"
    mys9s maintenance --list --long

    if s9s maintenance --list --long | grep --quiet "$reason"; then
        failure "The maintenance should have expired: '$reason'."
    fi

    return 0
}

#
# Dropping the cluster from the controller.
#
function testDrop()
{
    local exitCode

    print_title "Dropping the cluster"

    #
    # Dropping the cluster.
    #
    mys9s cluster \
        --drop \
        --cluster-id=$CLUSTER_ID \
        $LOG_OPTION
    
    exitCode=$?
    printVerbose "exitCode = $exitCode"
    if [ "$exitCode" -ne 0 ]; then
        failure "The exit code is ${exitCode}"
    fi
}

#
# Running the requested tests.
#
startTests
grant_user

if [ "$1" ]; then
    for testName in $*; do
        runFunctionalTest "$testName"
    done
else
    runFunctionalTest testPing
    runFunctionalTest testCreateCluster
    runFunctionalTest testCreateMaintenance
    runFunctionalTest testCreateTwoPeriods
    runFunctionalTest testDeletePeriods
    runFunctionalTest testClusterMaintenance
    runFunctionalTest testDrop
fi

endTests


