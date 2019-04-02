#!/usr/bin/env bash

# Exit script as soon as a command fails.
set -o errexit

# Allow to use profiles, then I can use fg
set -m

ganache_port=8545

ganache_running() {
    # verify if there is any server running on localhost
    # on port $ganache_port
    nc -z localhost "$ganache_port"
}

start_ganache() {
    # We define 10 accounts with balance 1M ether, needed for high-value tests.
    local accounts=(
        --account="0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501200,1000000000000000000000000"
        --account="0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501201,1000000000000000000000000"
        --account="0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501202,1000000000000000000000000"
        --account="0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501203,1000000000000000000000000"
        --account="0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501204,1000000000000000000000000"
        --account="0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501205,1000000000000000000000000"
        --account="0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501206,1000000000000000000000000"
        --account="0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501207,1000000000000000000000000"
        --account="0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501208,1000000000000000000000000"
        --account="0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501209,1000000000000000000000000"
    )

    # move to contracts folder so it can deploy the contracts to the network
    cd ../Contracts
    # verify if the ../chaindata folder exists and if not, create it, to store chain data
    if [[ ! -e ../chaindata ]]; then
        mkdir ../chaindata
    fi
    # run ganache-cli and put it on background so we can use the shell to deploy the contracts
    npx ganache-cli --mnemonic "rose current recycle double floor door scare dog lake claim rate lemon original fix better" --networkId "201904" --db="../chaindata" --host 0.0.0.0 --port "$ganache_port" "${accounts[@]}" &
    # get pid of ganache-cli
    export GANACHE_SHELL_PID=$!
    # wait for 10 seconds to let ganache start
    sleep 10
    # save a variable to know if the ganache instance was started by this script
    export USE_GANACHE_INSTANCE=script
}

# if we are running the script in start mode
if [[ $DEPLOY_ACTION = "start" ]]; then
    # if there is a ganache instance running, let's use it
    # other wise, let's start one
    if ganache_running; then
        echo "Using existing ganache instance"
        export USE_GANACHE_INSTANCE=external
    else
        echo "Starting our own ganache instance"
        start_ganache
        # verify if it's the first time running this container
        CONTAINER_ALREADY_STARTED="CONTAINER_ALREADY_STARTED_PLACEHOLDER"
        if [ ! -e $CONTAINER_ALREADY_STARTED ]; then
            touch $CONTAINER_ALREADY_STARTED
            # deploy contracts
            npx truffle deploy --network development
            # move to ui folder to perform extra actions
            cd ../ui
            # build the ui (needs to be after deploy contracts)
            npm run build
            # deploy test tokens
            npm run test-config
        fi
    fi
# if we are running the script in stop mode
elif [[ $DEPLOY_ACTION = "stop" ]]; then
    if [[ $USE_GANACHE_INSTANCE = "script" ]]; then
        # if the instance was started using this script then
        # kill using pid
        kill -9 GANACHE_SHELL_PID
    fi
fi
