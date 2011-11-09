#!/bin/bash
#
# Script for triggering load tests on several clients
# which are accessible via SSH. Clients need to have
# SSH public key access set up as well as the server (or
# the machine where this script is executed) has an SSH
# agent running for the current shell.

# Config
CLIENTS_IP_FILE="clients.txt"
NUM_CLIENTS=$( wc -l $CLIENTS_IP_FILE | cut -d' ' -f1) 
SSH_USERNAME="severin"
RUNNERS_PER_CLIENT=2
SUBMISSION_FILES_DIR="submission_files"
SCRIPTS="post_submissions.sh"
RESULTS_DIR="mb_results"

# Main
TOTAL_STUDENTS=$1
COLLECT=0

if [ "$1" == "-c" ]; then
	COLLECT=1
elif [ "$1" == "-h" ]; then 
	cat <<EOF
-----------------------------------------------------------------------------------

Load test script for MarkUs

	usage: $0 {-c|-h|NUM_STUDENTS}

In order to start load test runners on clients (requires proper SSH pub-key setup):

	$0 NUM_STUDENTS

Where NUM_STUDENTS is the total number of students you have created via rake. I.e.
$ bundle exec rake markus:benchmark:students_create num=NUM_STUDENTS

In order to collect results from clients after load simulations use:

	$0 -c

-----------------------------------------------------------------------------------

	$0 -h 	Prints this message.

EOF
	exit 0
fi

# Sanity checks for run_tests.
function sanity_check_config() {
	if [ "${TOTAL_STUDENTS}_" == "_" ]; then
		echo "usage: $0 NUM_STUDENTS" 1>&2
		exit 1
	fi

	if [ $(( $TOTAL_STUDENTS % $NUM_CLIENTS )) -ne 0 ]; then
		echo "Number of total students ($TOTAL_STUDENTS) not divisible by number of clients ($NUM_CLIENTS)." 1>&2
		exit 1
	fi

	block_range_per_client=$(( $TOTAL_STUDENTS / $NUM_CLIENTS ))
	if [ $(( $block_range_per_client % $RUNNERS_PER_CLIENT )) -ne 0 ]; then
		echo "Range per client ($block_range_per_client) not divisible by number of runners per client ($RUNNERS_PER_CLIENT)." 1>&2
		exit 1
	fi
}

# Kick off runners on clients
function run_test() {
	block_range=$(( $block_range_per_client / $RUNNERS_PER_CLIENT ))
	j=0
	for i in $(cat "$CLIENTS_IP_FILE"); do
		# Fire off runners per client
		for ((k=0; $k < $RUNNERS_PER_CLIENT; k++)); do
			# Note to self (Severin): This is most likely the most
			# unreadable bash snippet I've ever written :(
			ssh -l $SSH_USERNAME $i -f \
				 "cd mb; rm -rf log; ./post_submissions.sh $(( $(( $j * $block_range_per_client)) + $(( $(( $k * $block_range)) + 1)) )) $(( $(( $j * $block_range_per_client)) + $(($block_range * $(($k + 1)))) ))"
		done
	j=$(( j + 1))
	done
}

# Clean up on clients from previous runs
function cleanup_clients() {
	for i in $(cat "$CLIENTS_IP_FILE"); do
			ssh -l $SSH_USERNAME $i "rm -rf mb"
	done
}

# Collect logs from clients and put them into $RESULTS_DIR
function collect_results_from_clients() {
	logs_dir_new="mb_logs_$(date +%Y%m%d_%H%M%s)"
	# Make sure target dirs exist
	if [ ! -e $RESULTS_DIR ]; then
		mkdir $RESULTS_DIR
	fi
	for i in $(cat "$CLIENTS_IP_FILE"); do
		if [ ! -e "$RESULTS_DIR/$i" ]; then
			mkdir "$RESULTS_DIR/$i"
		fi
	done
	for i in $(cat "$CLIENTS_IP_FILE"); do
		scp -r $SSH_USERNAME@$i:mb/log $RESULTS_DIR/$i/$logs_dir_new
	done
}

# scp required files onto client machines so that
# they are ready to be used as load test runner.
function prepare_for_run() {
	# Make sure mb directory exists on client machines
	for i in $(cat "$CLIENTS_IP_FILE"); do
		ssh -l $SSH_USERNAME $i "if [ ! -e mb ]; then mkdir mb; fi"
	done
	for i in $(cat "$CLIENTS_IP_FILE"); do
		scp -r $SCRIPTS $SUBMISSION_FILES_DIR $SSH_USERNAME@$i:mb
	done
}

# Do the work :)
if [ $COLLECT -eq 0 ]; then
	cleanup_clients
	prepare_for_run
	sanity_check_config
	run_test
else
	collect_results_from_clients
fi
