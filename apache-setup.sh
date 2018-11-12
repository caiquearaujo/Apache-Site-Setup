#!/bin/bash

# Version 1.1
# Author: Caique Araujo
# E-mail: caique@studiopiggly.com.br

# Constants for color

# Red Color
RED='tput setaf 1'
# Green Color
GREEN='tput setaf 2'
# Default attributes
RESET='tput sgr0'
# Background White
WHITE='tput setab 7'
# Bold
BOLD='tput bold'

# Folders Constants

# Apache main directory
APACHE_DIR="/etc/apache2";
# Script file
SCRIPT=$(readlink -f "$0");
# Base directory of the script
BASEDIR=$(dirname "$SCRIPT");

# Blocking access if you're not the root/sudo user

if [[ $EUID > 0 ]] ; then
	echo 'Please you have to execute "Apache Site Setup" as a root/sudo user...';
	$RED
	$WHITE
	$BOLD
	echo 'Exiting of this script!';
	$RESET
	exit;
fi;

# Abort on error
set -e

# Show all command options
function help
{
	echo 'This command will configure a domain to be used in Apache 2. It will create a folder to a specific domain.';
	echo 'Then fix seetings to enable the site and do things in the right way.';
	echo 'Command usage: apache-setup -d DOMAIN [-dP FILE || -s SUBDOMAIN || -l PATH || -w PATH || -p PATH || -S || -SP FILE || -h]';
	echo '                            [--all || --folders || --perms || --logs || --config || --enables]';
	echo '  ';
	echo '-d  | --domain		: [REQUIRED] Domain to setup in Apache. E.X.: "example.com".';
	echo '-dP | --domain-provider	: Custom VHost configuration file. Default "default.apache.conf"';
	echo '-s  | --subdomain 	: Subdomain to setup in Apache. Only name. E.X.: "example".';
	echo '-l  | --log		: Custom log path to Apache website. E.X.: "/var/www/log".';
	echo '-w  | --www		: WWW path. E.X.: "/var/www/html". "Default: /var/www/html".';
	echo '-p  | --public		: Public path in Domain Folder. E.X.: "public_html"..';
	echo '-S  | --ssl		: Has SSL predefined. Default: "false".';
	echo '-SP | --ssl-provider	: Custom VHost configuration file to SSL. Default: "default.apache.ssl".';
	echo '-h  | --help		: This message.';
	echo '  ';
	echo 'Operations. Only one by execution.'
	echo '  ';
	echo '--all			: Execute all operations. By default.';
	echo '--folders 		: Creates the folders to domain.';
	echo '--perms			: Changes the domain folder permissions.';
	echo '--logs			: Creates the log folders to domain.';
	echo '--config  		: Creates the VHost configuration files.';
	echo '--enables 		: Enables the websites.';
}

# Parse all sending args
function parseArgs
{
	args=()

	command='all';

	while [ "$1" != "" ] ; do
		case "$1" in
			-d  | --domain          )	domain="$2";		shift;;
			-dP | --domain-provider )	dprovider="$S";		shift;;
			-s  | --subdomain       )	subdomain="$2";		shift;;
			-l  | --log             )	log="$2";		shift;;
			-w  | --www             )	www="$2";		shift;;
			-p  | --public          )	public="$2";		shift;;
			-S  | --ssl             )	ssl=true;		;;
			-SP | --ssl-provider    )	sprovider="$2"		shift;;
			--folders | --perms | --logs | --config | --enables )
				if [ "$1" = "--folders" ] ; then
                                        command='folders';
                                elif [ "$1" = "--perms" ] ; then
                                        command='perms';
                                elif [ "$1" = "--logs" ] ; then
                                        command='logs';
                                elif [ "$1" = "--config" ] ; then
                                        command='config';
                                elif [ "$1" = "--enables" ] ; then
                                        command='enables';
                                else
                                        command='all';
				fi;
				;;
			-h | --help             )	help;			exit;;	# Show help messages and quit
			*                       )	args+=("$1")			# If no match, add it to the positional args
		esac
		shift
	done

	required;
	defaults;
	validate;
}

function required
{
	# Needs to set domain
	if [[ -z "${domain}" ]] ; then
		$RED
		$WHITE
		$BOLD
		echo 'You have to provide the domain to continue...';
		$RESET
		help;
		exit;
	fi;
}

function defaults
{
	# Removing the Slashes
	if [[ -z "$www" ]] ; then
		www="/var/www/html";
	else
		www="${www%/}";
		www="${www#/}";
		www="/$www";
	fi;

	# Setting SSL as false, if not set
	if [[ -z "$ssl" ]] ; then
		ssl=false;
	fi;

	# Setting the VHost Configuration file with .conf
	if [[ -z "$dprovider" ]] ; then
		dprovider='default.apache.conf';
	else
		dprovider="${dprovider%.conf}";
		dprovider="$dprovider.conf";
	fi;

	# Setting the VHost Configuration file to SSL with .ssl.conf
	if [[ -z "$sprovider" ]] ; then
		sprovider='default.apache.ssl.conf';
	else
		sprovider="${sprovider%.ssl.conf}";
		sprovider="$sprovider.ssl.conf";
	fi;
}

function validate
{
	# Removing Slashes
        if [[ -n "$log" ]] ; then
                log="${log%/}";
                log="${log#/}";
                log="/${log}";
        fi;

	# Removing Slashes
        if [[ -n "$public" ]] ; then
                public="${public%/}";
                public="${public#/}";
        fi;

	# Rewriting the domain
	if [[ -n "$subdomain" ]] ; then
		domain="$subdomain.$domain";
	fi;
}

function createFolders
{
	echo 'Creating the folders...';
	$GREEN

	cd $www

	if [ ! -d "$www/$domain" ] ; then
		mkdir $domain
		echo "- Folder to domain created in \"${www}/${domain}\".";
	else
		echo "- Folder to domain already exists in \"${www}/${domain}\". Nothing change.";
	fi;

	cd $domain

	if [[ -n "$public" ]] ; then
		if [ ! -d "$www/$domain/$public" ] ; then
                	mkdir $public
                	echo "- Folder to public path created in \"${www}/${domain}/${public}\".";
        	else
                	echo "- Folder to public path already exists in \"${www}/${domain}/${public}\". Nothing change.";
        	fi;
	fi;

	$RESET
}

function configPerms
{
	echo 'Configuring permissions to domain folders...';

	cd $www
	chown -R www-data:www-data $domain
	find $domain -type f -exec chmod 644 {} \;
	find $domain -type d -exec chmod 755 {} \;

	$GREEN
        echo '- The domain path has the user "www-data" and group "www-data" as owner.';
        echo '- All folders inside domain path has 755 permissions, and the files has 644.';
        $RESET
}

function createLogs
{
	echo 'Configuring a specific log path to domain...';

	$GREEN
	if [[ -n "${log}" ]] ; then
		if [ ! -d "$log" ] ; then
			mkdir -p $log
			echo '- Creating the main log path...';
		else
			echo '- The log path already exists. Nothing change.';
		fi;

                if [ ! -d "$log/$domain" ] ; then
                        mkdir -p "$log/$domain"
                        echo '- Creating the log path for domain...';
                else
                        echo '- The log path for domain already exists. Nothing change.';
                fi;

		cd $log
		chown -R www-data:www-data $domain
		chmod 755 $domain

		echo "- The logs for domain is in \"${log}/${domain}\".";
	fi;
	$RESET
}

function createConfig
{
	echo 'Creating the Apache virtual host config file for domain...';
	cd $BASEDIR

	dtemplate="$domain.conf"
	cp $dprovider $dtemplate

	if [[ -z "$public" ]] ; then
		public="public_html";
	fi;

	if [[ -n "${log}" ]] ; then
                LOG_T="ErrorLog {{L}}\/{{DOMAIN}}\/error.log\n\tCustomLog {{L}}\/{{DOMAIN}}\/access.log combined";
                sed -i "s/{{LOGS}}/${LOG_T}/g" $dtemplate
		sed -i "s/{{L}}/${log//\//\\/}/g" $dtemplate
	else
		LOG_T="ErrorLog \$\{APACHE_LOG_DIR\}\/error.log\n\tCustomLog \$\{APACHE_LOG_DIR\}\/access.log combined";
                sed -i "s/{{LOGS}}/${LOG_T}/g" $dtemplate
                sed -i "s/{{L}}/${log//\//\\/}/g" $dtemplate
	fi;


	if [[ "$ssl" = true ]] ; then
		SSL_T="RewriteEngine On\n\tRewriteCond %{HTTPS} off\n\tRewriteRule ^ https:\/\/%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]";
		sed -i "s/{{SSL}}/${SSL_T}/g" $dtemplate
	fi;

	sed -i "s/{{LOGS}}/ /g" $dtemplate
	sed -i "s/{{DOMAIN}}/${domain}/g" $dtemplate
	sed -i "s/{{WWW}}/${www//\//\\/}/g" $dtemplate
	sed -i "s/{{PUBLIC_PATH}}/${public}/g" $dtemplate
	sed -i "s/{{SSL}}/ /" $dtemplate

	if [[ "$ssl" = true ]] ; then
		dstemplate="$domain.ssl.conf"
		cp $sprovider $dstemplate

		if [[ -n "${log-unset}" ]] ; then
	                LOG_T="ErrorLog {{L}}\/{{DOMAIN}}\/error.log\n\t\tCustomLog {{L}}\/{{DOMAIN}}\/access.log combined";
        	        sed -i "s/{{LOGS}}/${LOG_T}/g" $dstemplate
			sed -i "s/{{L}}/${log//\//\\/}/g" $dstemplate
        	else
                	LOG_T="ErrorLog \$\{APACHE_LOG_DIR\}\/error.log\n\tCustomLog \$\{APACHE_LOG_DIR\}\/access.log combined";
                	sed -i "s/{{LOGS}}/${LOG_T}/g" $dstemplate
                	sed -i "s/{{L}}/${log//\//\\/}/g" $dstemplate
        	fi;

        	sed -i "s/{{LOGS}}/ /g" $dstemplate
        	sed -i "s/{{DOMAIN}}/${domain}/g" $dstemplate
        	sed -i "s/{{WWW}}/${www//\//\\/}/g" $dstemplate
        	sed -i "s/{{PUBLIC_PATH}}/${public}/g" $dstemplate
        fi;

	mv $dtemplate $APACHE_DIR

	if [[ -e $dstemplate ]] ; then
		mv $dstemplate $APACHE_DIR
	fi;

	$GREEN
        echo "- The virtual hosts configuration files were created in \"${APACHE_DIR}\".";
        echo '- Edit them if you want to change some kind of specific configuration.';
        $RESET
}

function enableDomain
{
	echo 'Preparing to enable domain in Apache...';
	a2ensite "$domain.conf"

	if [[ "$ssl" = true ]] ; then
		a2ensite "$domain.ssl.conf"
	fi;

	service apache2 reload

	$GREEN
        echo '- The domain was successfully enabled.';
        echo '- Online for use.';
	$RESET
}

function run
{
	parseArgs "$@"

	# Rewriting APACHE_DIR
	APACHE_DIR="$APACHE_DIR/sites-available";

	$GREEN
	$BOLD
	echo "Starting Apache Site Setup for \"${domain}\" domain...";
	$RESET

	if [ "$command" = "folders" ] ; then
                createFolders;
        elif [ "$command" = "perms" ] ; then
                configPerms;
        elif [ "$command" = "logs" ] ; then
                createLogs;
        elif [ "$command" = "config" ] ; then
                createConfig;
        elif [ "$command" = "enables" ] ; then
                enableDomain;
	else
                createFolders;
                configPerms;
                createLogs;
                createConfig;
                enableDomain;
	fi;

	$GREEN
	$BOLD
	echo 'Everything is done here.';
	$RESET
}

run "$@";
