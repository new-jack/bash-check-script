#!/bin/bash
## Robert Wessinger - 24 JUL 2019
## Used to check system settings, running service, etc. 


# Variable Declaration

	# Formatting Variables
	dot=$(echo -e "\u25CF")
	wid=$(tput cols)
	total=$(( $wid - 23 ))
	SUCCESS=$(tput setaf 2; tput bold; echo "SUCCESS")
	#SUCCESS=$(tput setaf 2; tput bold; echo -e "\033[0;32m\xE2\x9C\x94\033[0m")
	FAIL=$(tput setaf 1; tput bold; echo "FAIL")
	#FAIL=$(tput setaf 1; tput bold; tput blink; echo -e "\u274c")
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

                services=(httpd mariadb smb firewalld foo)
		numberOfServices="${#services[@]}"
		loopNum=1

		if [[ $saveOutput == "1" ]]; then
			echo "{" >> $outputFile
			echo "	"\""services"\"": {" >> $outputFile
		fi

                for i in "${services[@]}"; do
			message="Check $i is running"
                        len=$(echo $message | wc -c)
                        difference=$(( $total - $len - 7 ))
			cmdOutput=$(systemctl is-active $i 2> /dev/null)
                        cmdOutput=$?
	
			if [[ $saveOutput == "1" ]]; then
				if [[ $loopNum ==  $numberOfServices ]]; then
					echo "		"\""$i"\"": "\""$cmdOutput"\""" >> $outputFile
					break
				else
					if [[ $saveOutput == "1" ]]; then
					echo "		"\""$i"\"": "\""$cmdOutput"\""," >> $outputFile
					fi

				fi	
			fi
						
			
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

			loopNum=$((loopNum + 1))
                done



		if [[ $saveOutput == "1" ]]; then
			echo "	}," >> $outputFile
		fi

	}


function Check-Dns ()
	{
		tput bold; echo -e \\n"Check DNS Functionality"\\n; tput sgr0
		nameServer="8.8.8.8"
		message="Check resolv.conf settings"
		len=$(echo $message | wc -c)
		difference=$(( $total - $len - 7 ))
	
		if [[ $saveOutput == "1" ]]; then
			echo "	"\""namerservers"\"": {" >> $outputFile
		fi

		grepTest=$(grep -v "#" /etc/resolv.conf | grep -c "$nameServer")
		if [[ $nameserver -ge "1" ]]; then
			Print-Message " " $difference $dot "$message" "$SUCCESS" && tput sgr0
			if [[ $saveOutput == "1" ]]; then
				echo "		"\""$nameServer"\"": "\""$grepTest"\""" >> $outputFile
			fi
		else
			Print-Message " " $difference $dot "$message" "$FAIL" && tput sgr0
			echo -e "\tCHECK: $message" >> $fail_log
			echo -e "\t\tRESULT: Could not find nameserver 8.8.8.8 in resolv.conf"\\n >> $fail_log
			if [[ $saveOutput == "1" ]]; then
				echo "		"\""$nameServer"\"": "\""$grepTest"\""" >> $outputFile
			fi
		fi

		if [[ $saveOutput == "1" ]]; then
			echo "	}," >> $outputFile
		fi
	
		message="Try pinging google.com"
		len=$(echo $message | wc -c)
		difference=$(( $total - $len - 7 ))
		pingSite="google.com"

		if [[ $saveOutput == "1" ]]; then
			echo "	"\""ping-test"\"": {" >> $outputFile

		fi

		pingTest=$(ping -c 3 $pingSite 2>> /dev/null)
		cmdOutput=$?
			
		if [[ $saveOutput == "1" ]]; then
			echo "		"\""$pingSite"\"": "\""$cmdOutput"\""" >> $outputFile
		fi

		
		if [[ $cmdOutput -eq "0" ]]; then
			Print-Message " " $difference $dot "$message" "$SUCCESS" && tput sgr0
			
		else
			Print-Message " " $difference $dot "$message" "$FAIL" && tput sgr0
			echo -e "\tCHECK: $message" >> $fail_log
			echo -e "\t\tRESULT: could not ping google.com"\\n >> $fail_log
		fi

		if [[ $saveOutput == "1" ]]; then
			echo "	}," >> $outputFile
		fi

	}

function Check-Diskspace ()
	{
		tput bold; echo -e \\n"Check Disk Usage"\\n; tput sgr0
		message="See if any disks are full"
		len=$(echo $message | wc -c)
		difference=$(( $total - $len - 7 ))
		
		if [[ $saveOutput == "1" ]]; then
			echo "	"\""disk-check"\"": {" >> $outputFile
		fi

		diskFull=$(df -h | awk '{print $5}' | grep -c "100")
		
		if [[ $diskFull -lt "1" ]]; then
			Print-Message " " $difference $dot "$message" "$SUCCESS" && tput sgr0
			if [[ $saveOutput == "1" ]]; then
				echo "		"\""$nameServer"\"": "\""$grepTest"\""" >> $outputFile
			fi
		else
			Print-Message " " $difference $dot "$message" "$FAIL" && tput sgr0
			if [[ $saveOutput == "1" ]]; then
				echo "		"\""$nameServer"\"": "\""$grepTest"\""" >> $outputFile
			fi
		fi
			
		if [[ $saveOutput == "1" ]]; then
			echo "	}" >> $outputFile
			echo "}" >> $outputFile
		fi
			
	}

if [ ! -z "$1" ]; then
	if [[ $1 == '--out' ]]; then
		out=1
		if [ ! -z $2 ]; then
			outputFile=$2
		fi
	else
		echo "$1 is unknown. Please use flag --out"
	fi
fi


if [ ! -z $out ] && [ ! -z $outputFile ]; then 
	if [ -f $outputFile ]; then
		if ! $(truncate -s 0 $outputFile); then 
			echo "Couldn't truncate $outputFile"
		       	exit
		else
			saveOutput=1
	        fi
	else
		if ! $(touch $outputFile); then 
			echo "Couldn't create file $outputFile"
			exit
		else
			saveOutput=1
		fi
		exit
	fi

fi	



Check-Services
Check-Dns
Check-Diskspace
tput bold; tput setaf 1; tput smul
echo -e \\n\\n"Failed Checks (output from $fail_log)"; tput sgr0
echo -e "\t$(cat $fail_log)"\\n\\n
