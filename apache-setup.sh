#!/bin/bash

# Constants for color

RED='tput setaf 1'
GREEN='tput setaf 2'
RESET='tput sgr0'

# Folders Constants
APACHE_DIR="/etc/apache2";
SCRIPT=$(readlink -f "$0");
BASEDIR=$(dirname "$SCRIPT");

# Blocking access if you're not the root/sudo user

if [[ $EUID > 0 ]] ; then
	echo 'Please you have to execute "Apache Site Setup" as a root/sudo user...';
	$RED
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
	echo 'Command usage: apache-setup -d DOMAIN [-s SUBDOMAIN || -l LOG PATH || -w WWW PATH || -p PUBLIC PATH || -S HAS SSL || -SP SSL PROVIDER || -h]';
	echo '  ';
	echo '-d  | --domain		: [REQUIRED] Domain to setup in Apache. E.X.: "example.com".';
	echo '-s  | --subdomain		: Subdomain to setup in Apache. Only name. E.X.: "example".';
	echo '-l  | --log		: Custom log path to Apache website. E.X.: "/var/www/log".';
	echo '-w  | --www                : WWW path. E.X.: "/var/www/html". "Default: /var/www/html".';
	echo '-p  | --public		: Public path in Domain Folder. E.X.: "public_html". Default: "public_html".';
	echo '-S  | --ssl		: Has SSL predefined. Default: "false".';
	echo '-SP | --ssl-provider	: The model for ".conf" file. Default: "default.apache.ssl".';
	echo '-h  | --help		: This message.';
}

# Parse all sending args
function parseArgs
{
	args=()

	while [ "$1" != "" ] ; do
		case "$1" in
			-d  | --domain       )		domain="$2";		shift;;
			-s  | --subdomain    )		subdomain="$2";		shift;;
			-l  | --log          )		log="$2";		shift;;
			-w  | --www          )		www="$2";		shift;;
			-p  | --public       )		public="$2";		shift;;
			-S  | --ssl          )		ssl=true;		shift;;
			-SP | --ssl-provider )		sprovider="$2"		shift;;
			-h  | --help         )		help;			exit;;	# Show help messages and quit
			*                    )		args+=("$1")			# If no match, add it to the positional args
		esac
		shift
	done

	# Required args
	if [[ -z "${domain}" ]] ; then
		$RED
		echo 'You have to provide the domain to continue...';
		$RESET
		help;
		exit;
	fi;

	# Setting the defaults values
	if [[ -z "$www" ]] ; then
		www="/var/www/html";
	fi;

	if [[ -z "$public" ]] ; then
		public="public_html";
	fi;

	if [[ -z "$ssl" ]] ; then
		ssl=false;
	fi;

	if [[ -z "$sprovider" ]] ; then
		sprovider='default.apache.ssl.conf';
	else
		sprovider="$sprovider.conf";
	fi;
}

function run
{
	parseArgs "$@"

	# Rewrinting the domain
	if [[ -n "${subdomain}" ]] ; then
		domain="$subdomain.$domain";
	fi;

	# Rewriting APACHE_DIR
	APACHE_DIR="$APACHE_DIR/sites-available";

	$GREEN
	echo "Starting configuring the Apache website for \"${domain}\" domain...";
	$RESET

	echo 'Creating the folders...';
	$GREEN

	cd $www

	if [ ! -d "$www/$domain" ] ; then
		mkdir $domain
		echo "Folder to domain created in \"${www}/${domain}\".";
	else
		echo "Folder to domain already exists in \"${www}/${domain}\". Nothing change.";
	fi;

	cd $domain

	if [ ! -d "$www/$domain/$public" ] ; then
                mkdir $public
                echo "Folder to public path created in \"${www}/${domain}/${public}\".";
        else
                echo "Folder to public path already exists in \"${www}/${domain}/${public}\". Nothing change.";
        fi;

	$RESET

	echo 'Configuring permissions to folders created...';
	cd $www
	chown -R www-data:www-data $domain
	find $domain -type f -exec chmod 644 {} \;
	find $domain -type d -exec chmod 755 {} \;

	$GREEN
        echo 'The domain path has the user "www-data" and group "www-data" as owner.';
        echo 'All folders inside domain path has 755 permissions, and the files has 644.';
        $RESET

	if [[ -n "${log}" ]] ; then
		if [ ! -d "$log" ] ; then
			mkdir -p $log
			echo 'Creating the main log path...';
		else
			echo 'The log path already exists. Nothing change.';
		fi;

                if [ ! -d "$log/$domain" ] ; then
                        mkdir -p "$log/$domain"
                        echo 'Creating the log path for domain...';
                else
                        echo 'The log path for domain already exists. Nothing change.';
                fi;

		cd $log
		chown -R www-data:www-data $domain
		chmod 755 $domain

		$GREEN
		echo "The logs for domain is in \"${log}/${domain}\".";
		$RESET
	fi;

	echo 'Creating the Apache virtual host config file for domain...';
	cd $BASEDIR

	cp default.apache.conf "$domain.conf"

	if [[ -n "${log}" ]] ; then
                LOG_T="ErrorLog {{L}}\/{{DOMAIN}}\/error.log\n\tCustomLog {{L}}\/{{DOMAIN}}\/access.log combined";
                sed -i "s/{{LOGS}}/${LOG_T}/g" "$domain.conf"
		sed -i "s/{{L}}/${log//\//\\/}/g" "$domain.conf"
	else
		LOG_T="ErrorLog \$\{APACHE_LOG_DIR\}\/error.log\n\tCustomLog \$\{APACHE_LOG_DIR\}\/access.log combined";
                sed -i "s/{{LOGS}}/${LOG_T}/g" "$domain.conf"
                sed -i "s/{{L}}/${log//\//\\/}/g" "$domain.conf"
	fi;


	if [[ "$ssl" = true ]] ; then
		SSL_T="RewriteEngine On\n\tRewriteCond %{HTTPS} off\n\tRewriteRule ^ https:\/\/%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]";
		sed -i "s/{{SSL}}/${SSL_T}/g" "$domain.conf"
	fi;

	sed -i "s/{{LOGS}}/ /g" "$domain.conf"
	sed -i "s/{{DOMAIN}}/${domain}/g" "$domain.conf"
	sed -i "s/{{WWW}}/${www//\//\\/}/g" "$domain.conf"
	sed -i "s/{{PUBLIC_PATH}}/${public}/g" "$domain.conf"
	sed -i "s/{{SSL}}/ /" "$domain.conf"

	if [[ "$ssl" = true ]] ; then
		cp $sprovider "$domain.ssl.conf"
		if [[ -n "${log-unset}" ]] ; then
	                LOG_T="ErrorLog {{L}}\/{{DOMAIN}}\/error.log\n\t\tCustomLog {{L}}\/{{DOMAIN}}\/access.log combined";
        	        sed -i "s/{{LOGS}}/${LOG_T}/g" "$domain.ssl.conf"
			sed -i "s/{{L}}/${log//\//\\/}/g" "$domain.ssl.conf"
        	else
                	LOG_T="ErrorLog \$\{APACHE_LOG_DIR\}\/error.log\n\tCustomLog \$\{APACHE_LOG_DIR\}\/access.log combined";
                	sed -i "s/{{LOGS}}/${LOG_T}/g" "$domain.conf"
                	sed -i "s/{{L}}/${log//\//\\/}/g" "$domain.conf"
        	fi;

        	sed -i "s/{{LOGS}}/ /g" "$domain.ssl.conf"
        	sed -i "s/{{DOMAIN}}/${domain}/g" "$domain.ssl.conf"
        	sed -i "s/{{WWW}}/${www//\//\\/}/g" "$domain.ssl.conf"
        	sed -i "s/{{PUBLIC_PATH}}/${public}/g" "$domain.ssl.conf"
        fi;

	mv "$domain.conf" $APACHE_DIR

	if [[ -e "$domain.ssl.conf" ]] ; then
		mv "$domain.ssl.conf" $APACHE_DIR
	fi;

	$GREEN
        echo "The virtual hosts configuration files were created in \"${APACHE_DIR}\".";
        echo 'Edit them if you want to change some kind of specific configuration.';
        $RESET

	echo 'Preparing to enable domain in Apache...';
	a2ensite "$domain.conf"

	if [[ "$ssl" = true ]] ; then
		a2ensite "$domain.ssl.conf"
	fi;

	service apache2 reload

	$GREEN
        echo 'The domain was successfully enabled.';
        echo 'Online for use.';
	echo 'Everything is done here.';
	$RESET
}

run "$@";
