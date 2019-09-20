# bash-check-script
Basic system checks with formatting. Tested on CentOS 7 only.

The script run multiple checks and outputs information with formatting.

Can be modified to check for anything. Currently, it checks for resolv.conf settings, running services (via an array), disk space, and ping tests. 

Note: The service checks run systemctl commands. Replace them with the 'service' command on line 47 to run on CentOS/RHEL 6. To change the services that are checked, update the 'services' array variable on line 39. 

Note: For testing purposes, a bogus serivce with the name of 'lkjsdf' has been placed in the services array on line 39. 
