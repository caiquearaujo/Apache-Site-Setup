# Apache Site Setup

## Goals

Know when you have to do the same things many many times? It's a lot boring, mainly when you're working in your own server creating a lot of domains & subdomains to your projects.

The bash script **Apache Site Setup** born to solve all of your problems. Take a look in what it does:

1. Creates the domain/subdomain folder in apache "/var/www/html" or custom path;
2. Creates a custom public html folder inside the folder created before;
3. Changes the owner of folders created to "www-data" user/group;
4. Changes the permissions as: 755 to directories and 644 to files;
5. Creates a custom log path, to control better the error of each domain/subdomain;
6. Creates the vhosts configuration file to http and https website;
7. Enables the websites and reloads Apache.

## How to Use

The bash script is really easy to use. There are some considerations about your parameters. Take a look:

### DOMAIN (REQUIRED)
The main domain. By using the commands `-d` or `--domain`.
You type in the following format: `example.com`.

### SUBDOMAIN (OPTIONAL)
The subdomain to configure. By using the commands `-s` or `--subdomain`.
You type in the following format: `name`.

**IMPORTANT** 
You don't have to add a dot or the domain name, only the subdomain name.
In this way, all script will focus in `name.example.com`.

### LOG PATH (OPTIONAL)
Where to save the errors log. By using the commands `-l` or `--log`.
Sometimes it's better make error logs to be in separeted folders.
Here you setup the main folder to store all logs.
You type in the following format: `/var/www/log`.

**BY DEFAULT** it uses `${APACHE_LOG_DIR}`.

### WWW PATH (OPTIONAL)
The www folder. By using the commands `-w` or `--www`.
You type in the following format: `/var/www/html`.

**BY DEFAULT** it uses `/var/www/html`.

### PUBLIC PATH (OPTIONAL)
The public folder. By using the commands `-p` or `--public`.
You type in the following format: `public_html`.

**IMPORTANT** 
You just have to write the public folder name.
It will be created inside the domain/subdomain folder.

**BY DEFAULT** it uses `public_html`.

### SSL (OPTIONAL)
Enables the SSL. By using the commands `-S` or `--ssl`.
You don't have to type nothing, just type the command.

**BY DEFAULT** it uses `false`.

### SSL PROVIDER (OPTIONAL)
The provider configuration file. By using the commands `-SP` or `--ssl-provider`.
You type in the following format: `default.apache.ssl` file name without extension.

Each provider was your own path and way to store the SSL keys, and somekind more configuration in vhost file.
Everything you have to do is copy the `default.apache.ssl.conf` file and edit in the way you want.
If you save the file as `default.comodo.ssl.conf` you have to use `default.comodo.ssl` in this command.

**IMPORTANT** 
You don't have to add the extension `.conf`, just the file name.

**BY DEFAULT** it uses `default.apache.ssl`.

## The Configuration Files
As you see, you have three files `.conf` and they are essential to make the vhost configuration in Apache `sites-available` folder.
You can edit them how you want. The script will copy everything of defaults files. So, don't delete `default.apache.conf` and `default.apache.ssl.conf`. They are the base of everything.

### Files

1. `default.apache.conf` has the default HTTP configuration.
2. `default.apache.ssl.conf` has the default HTTPS configuration.
3. `default.letsencrypt.ssl.conf` has the default HTTPS configuration to Let's Encrypt.

### Variables
Here are the variables that you be replaced in the file:

1. `{{DOMAIN}}` with the domain/subdomain;
2. `{{WWW}}` with the www folder;
3. `{{PUBLIC}}` with the public html folder;
4. `{{LOGS}}` with the ErroLog and CustomLog expressions;
5. `{{SSL}}` with the SSL rewrites.

## What's next?
For now, it's a lot good. But there are some considerations we can improve:

1. Filter each variable typed in the terminal;
2. Setup the public folder creation as optional;
3. A command to only execute somekind of tasks. For example: only changes permissions of folders or only create the folders;
4. Improve the default configuration files, creating them if them don't exist.

## Version
1.0.0
