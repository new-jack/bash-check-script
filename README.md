# bash-check-script
Basic system checks with formatting. Tested on CentOS 7 only.

The script run multiple checks and outputs information with formatting.

Can be modified to check for anything. Currently, it checks for resolv.conf settings, running services (via an array), disk space, and ping tests. 

Note: The service checks run systemctl commands. Replace them with 'service' commands to run on CentOS/RHEL 6. 
