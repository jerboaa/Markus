#!/bin/bash
#set -xv

function usage(){
	echo "usage: $0 <student-number-from> <student-number-to>" 1>&2
	echo "" 1>&2
	echo "example: $0 0 10" 1>&2
	exit 1
}

function submit_files(){
	USER=$1
	# log in
	$TIME_PROG -f "$TIME_FORMAT" curl -c "$COOKIE_JAR" -v "$MARKUS_BASE_URL"
	$TIME_PROG -f "$TIME_FORMAT" curl -b "$COOKIE_JAR" -c "$COOKIE_JAR" --data "user_login=$USER" --data "user_password=blah" -v "$MARKUS_BASE_URL"
	# should be logged in now and get a redirect to main/assignments
	$TIME_PROG -f "$TIME_FORMAT" curl -b "$COOKIE_JAR" -c "$COOKIE_JAR" -v "$MARKUS_BASE_URL/main"
	# request the assignments list page
	$TIME_PROG -f "$TIME_FORMAT" curl -b "$COOKIE_JAR" -c "$COOKIE_JAR" -v "$MARKUS_BASE_URL/main/assignments"
	# create the subversion repository
	$TIME_PROG -f "$TIME_FORMAT" curl -b "$COOKIE_JAR" -c "$COOKIE_JAR" -v "$MARKUS_BASE_URL/main/assignments/student_interface/1"
	# load the file manager
	$TIME_PROG -f "$TIME_FORMAT" curl -b "$COOKIE_JAR" -c "$COOKIE_JAR" -v "$MARKUS_BASE_URL/main/submissions/file_manager/1"
	# submit files
	new_files_param_pre="-F new_files[]=@"
	new_files_param_post=" "
	new_files_param=""
	# Build new_files_parameter. I.e. upload all files at once (one request)
	for submission_file in $( find "$SUBMISSION_FILES_FOLDER" -name "*.rb" ); do
		# construct curl parameters for submission files
		new_files_param="${new_files_param}${new_files_param_pre}${submission_file}${new_files_param_post}"
	done
	# Make sure that you are not submitting the same filename twice as this will
	# result in a conflict and therefore no submissions will be maded at all.
	$TIME_PROG -f "$TIME_FORMAT" curl -b "$COOKIE_JAR" -c "$COOKIE_JAR" -v $new_files_param "$MARKUS_BASE_URL/main/submissions/update_files/1"
}

# CONFIG
COOKIE_JAR="markus-cookie-jar.txt"
SUBMISSION_FILES_FOLDER="./submission_files"
MARKUS_BASE_URL="http://tikal.red.sandbox/markus/en"
LOGDIR=log

# Main
STUDENT_NUMBER_FROM=$1
STUDENT_NUMBER_TO=$2
TIME_PROG="/usr/bin/time"
TIME_FORMAT='+++ELAPSED TIME+++ %e +++'

# sanity checks
if [ $# -lt 2 ] || [ $STUDENT_NUMBER_FROM -lt 0 ] ||
   [ $STUDENT_NUMBER_TO -lt 0 ] || [ $STUDENT_NUMBER_TO -lt $STUDENT_NUMBER_FROM ]; then
	usage
fi

if ! $( which curl > /dev/null 2>&1 ); then
	echo "$0 requires curl which is not in your PATH" 1>&2
	exit 1
fi

# create logdir if not existing
if [ ! -e $LOGDIR ]; then
	mkdir $LOGDIR
fi

for i in $( seq $STUDENT_NUMBER_FROM $STUDENT_NUMBER_TO ); do
	submit_files "student_$i" > "$LOGDIR/student_$i.log" 2>&1
done

exit 0
