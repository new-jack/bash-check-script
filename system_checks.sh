#!/bin/bash
## Robert Wessinger - 24 JUL 2019
## Used to check system settings, running service, etc. 


# Variable Declaration

	# Formatting Variables
	damon=$(systemctl list-unit-files | grep enabled | head -n 1 | awk '{print $1}')
	dot=$(systemctl status $damon | head -n 1  | cut -d " " -f 1)
	wid=$(tput cols)
	total=$(( $wid - 23 ))
	SUCCESS=$(tput setaf 2; tput bold; echo "SUCCESS")
	FAIL=$(tput setaf 1; tput bold; echo "FAIL")
        WARNING=$(tput setaf 3; tput bold; echo "WARNING")
	
	# General Variables
	fail_log=/tmp/fail_log.txt


echo > $fail_log

function Print-Message () 
	{
		 str=$1
		 num=$2
		 v=$(printf "%-${num}s" "$str")
		 echo -e "\t$3 $4 ${v// /.} $5"
	}

function Check-Services ()
	{
		tput bold; echo -e \\n"Check that vital services are running"\\n; tput sgr0

                services=(httpd mariadb smb firewalld lkjsdf)

                for i in "${services[@]}"; do

                        message="Check $i is running"
                        len=$(echo $message | wc -c)
                        difference=$(( $total - $len - 7 ))
                        #cmdOutput=$(systemctl status $i 2> /dev/null | grep -c "active")
                        cmdOutput=$(systemctl status $i 2> /dev/null)
                        cmdOutput=$?

                        if [[ $cmdOutput == "0" ]]; then
                                Print-Message " " $difference $dot "$message" "$SUCCESS" && tput sgr0
                        elif [[ $cmdOutput == "1" ]]; then
                                Print-Message " " $difference $dot "$message" "$FAIL" && tput sgr0
                                echo -e "\tCHECK: Check status of $i" >> $fail_log
                                echo -e "\t\tRESULT: Return Code was 1. Loaded but FAILED" >> $fail_log
                                echo -e "\t\tRECCOMENDATION: systemctl status -l $i or journalctl -xe for more info"\\n >> $fail_log
                        elif [[ $cmdOutput == "3" ]]; then
                                Print-Message " " $difference $dot "$message" "$WARNING" && tput sgr0
                                echo -e "\tCHECK: Check status of $i" >> $fail_log
                                echo -e "\t\tRESULT: Return Code was 3. Loaded but not active" >> $fail_log
                                echo -e "\t\tRECCOMENDATION: If needed, run systemctl start $i"\\n >> $fail_log
                        elif [[ $cmdOutput == "4" ]]; then
                                Print-Message " " $difference $dot "$message" "$FAIL" && tput sgr0
                                echo -e "\tCHECK: Check status of $i" >> $fail_log
                                echo -e "\t\tRESULT: Return Code was 4. Service not found (not installed)"\\n >> $fail_log
                        else
                                Print-Message " " $difference $dot "$message" "$FAIL" && tput sgr0
                                echo -e "\tCHECK: Check status of $i" >> $fail_log
                                echo -e "\t\tRESULT: Could not find status of $i" >> $fail_log
                                echo -e "\t\tRECCOMENDATION: Try running systemctl status $i"\\n >> $fail_log
                        fi
                done

	}


function Check-Dns ()
	{
		tput bold; echo -e \\n"Check DNS Functionality"\\n; tput sgr0
		message="Check resolv.conf settings"
		len=$(echo $message | wc -c)
		difference=$(( $total - $len - 7 ))
		
		nameserver=$(grep -v "#" /etc/resolv.conf | grep -c "8.8.8.8")

		if [[ $nameserver -ge "1" ]]; then
			Print-Message " " $difference $dot "$message" "$SUCCESS" && tput sgr0
		else
			Print-Message " " $difference $dot "$message" "$FAIL" && tput sgr0
			echo -e "\tCHECK: $message" >> $fail_log
			echo -e "\t\tRESULT: Could not find nameserver 8.8.8.8 in resolv.conf"\\n >> $fail_log
		fi
	
		message="Try pinging google.com"
		len=$(echo $message | wc -c)
		difference=$(( $total - $len - 7 ))

		pingTest=$(ping -c 3 google.com 2>> /dev/null)

		if [[ $? -eq "0" ]]; then
			Print-Message " " $difference $dot "$message" "$SUCCESS" && tput sgr0
		else
			Print-Message " " $difference $dot "$message" "$FAIL" && tput sgr0
			echo -e "\tCHECK: $message" >> $fail_log
			echo -e "\t\tRESULT: could not ping google.com"\\n >> $fail_log
		fi
			
	}

function Check-Diskspace ()
	{
		tput bold; echo -e \\n"Check Disk Usage"\\n; tput sgr0
		message="See if any disks are full"
		len=$(echo $message | wc -c)
		difference=$(( $total - $len - 7 ))
			
		diskFull=$(df -h | awk '{print $5}' | grep -c "100")
		
		if [[ $diskFull -lt "1" ]]; then
			Print-Message " " $difference $dot "$message" "$SUCCESS" && tput sgr0
		else
			Print-Message " " $difference $dot "$message" "$FAIL" && tput sgr0
		fi
			
			
	}


Check-Services
Check-Dns
Check-Diskspace
tput bold; tput setaf 1; tput smul
echo -e \\n\\n"Failed Checks (output from $fail_log)"; tput sgr0
echo -e "\t$(cat $fail_log)"\\n\\n
