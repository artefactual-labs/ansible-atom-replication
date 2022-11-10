Three servers scenario
======================

We have 3 servers:

AtoM server, let's call this server `atom-nginx`:

* The server includes the following services: nginx, atom-workers
* IP Address: 1.2.3.4
* ssh user: artefactual
* OS: Ubuntu 20
* edit site URL: https://edit.replication.accesstomemory.org
* read-only site URL: https://ro.replication.accesstomemory.org
* edit AtoM path: /usr/share/nginx/atom-edit
* read-only AtoM path: /usr/share/nginx/atom-ro

MySQL server, let's call this server `atom-mysql`:

* The server includes the following services: mysql
* IP Address: 5.6.7.8
* ssh user: artefactual
* OS: Ubuntu 20
* edit database: atom-edit
* read-only database: atom-ro

Elasticsearch server, let's call this server `atom-es`:

* The server includes the following services: Elasticsearch
* IP Address: 9.8.7.6
* ssh user: artefactual
* OS: Ubuntu 20
* edit ES index: atom-edit
* read-only ES index: atom-ro

For this replication, we want:

* Install the replication ansible environment on the `atom-nginx`, at `/usr/share/nginx/atom-replication` directory
* schedule a weekly replication at 3:23 AM, every Saturday, and send email notifications to: "my_email@example.com"
* Don't copy clipboard and access log tables
* Remove deleted items in clipboard. If the read-only clipboard (we are not copying the clipboard from edit site on read-only) has any item that has been deleted in the replication, then remove it from clipboard table
* The 2 servers are using the same base URL (using the read-only on both), so we don't want to change the baseurl in downloads directory files
* The uploads and downloads directory are not going to be synchronized because they are the same (using symlinks)
* Run the `php symfony cc` command and delete temporary data (clipboards, access log and downloads) older than 1 month (See [Delete temporary data (saved clipboards, access log, and downloads)](https://www.accesstomemory.org/en/docs/2.7/admin-manual/maintenance/cli-tools/#delete-temporary-data-saved-clipboards-access-log-and-downloads))
* Restart memcached, php-fpm and both atom workers

Deploy ansible environment on server
====================================

In your computer you must have:

* ansible>=2.10 with the ansible.posix, community.general and community.mysql collections.
* ssh connection the all-in-one-server using artefactual user (sudo privileges on server)
* This role downloaded on `roles/artefactual.ansible-atom-replication` dir

## Create ansible 2.12.5 virtualenv (Optional)

If you are not using ansible>2.10 in your computer, you always can install a virtualenv with the desired version. For instance, to create a virtualenv at `$HOME/artefactual/venv-ansible-2.12.5`

```
cd $HOME/artefactual
virtualenv -p python3 venv-ansible-2.12.5
source venv-ansible-2.12.5/bin/activate
pip install --upgrade pip
pip install ansible-core==2.12.5
ansible-galaxy collection install ansible.posix
ansible-galaxy collection install community.general
ansible-galaxy collection install community.mysql
```

To exit from the virtualenv just run:

```
deactivate
```

And to use the virtualenv you only need to run:

```
source $HOME/artefactual/venv-ansible-2.12.5/bin/activate
```

## Ansible inventory in your computer

Your ansible inventory must contain at least something like:

```

atom-nginx	ansible_ssh_host=1.2.3.4	ansible_ssh_user=artefactual
atom-mysql      ansible_ssh_host=5.6.7.8        ansible_ssh_user=artefactua
atom-es		ansible_ssh_host=9.8.7.6        ansible_ssh_user=artefactual

```

## Replication config file at `host_vars/atom-nginx/replication-config.yml`

When using the `install-replication` tag, the suggested install playbook looks for the replication-config.yml file in the following directories (the first found is the one that is used):

* `host_vars/atom-nginx/replication-config.yml`
* `files/atom-nginx/replication-config.yml`
* Any other file defined as extra-var with: `-e atom_replication_config=YOUR_FILE`

In this example, we are going to use the first option, so we need to create the following file:

```
---

# Servers (Ansible host field in Ansible inventory)
atom_replication_edit_atom_host: "atom-nginx"
atom_replication_ro_atom_host: "atom-nginx"
atom_replication_edit_mysql_host: "atom-mysql"
atom_replication_ro_mysql_host: "atom-mysql"
atom_replication_edit_es_host: "atom-es"
atom_replication_ro_es_host: "atom-es"


# Ansible ssh IP addresses/hostnames (Ansible ssh host in Ansible inventory)
atom_replication_edit_atom_ansible_host: "localhost"
atom_replication_ro_atom_ansible_host: "localhost"
atom_replication_edit_es_ansible_host: "9.8.7.6"
atom_replication_ro_es_ansible_host: "9.8.7.6"
atom_replication_ro_mysql_ansible_host: "5.6.7.8"
atom_replication_edit_mysql_ansible_host: "5.6.7.8"

# Install role in remote server (Optional).
# Use "install-replication" tag to deploy the replication script in the remote server
atom_replication_ansible_remote_server: "localhost"
atom_replication_ansible_remote_user: "artefactual"
atom_replication_ansible_remote_path: "/usr/share/nginx/atom-replication"

atom_replication_ansible_remote_cron_enabled: True
atom_replication_ansible_remote_cron_minute: "23"
atom_replication_ansible_remote_cron_hour: "3"
atom_replication_ansible_remote_cron_day: "*"
atom_replication_ansible_remote_cron_month: "*"
atom_replication_ansible_remote_cron_weekday: "SAT"
atom_replication_ansible_remote_cron_mailto: "my_email@example.com"

# Elasticsearch settings:

atom_replication_edit_es_index: "atom-edit"
atom_replication_ro_es_index: "atom-ro"

# MySQL settings
atom_replication_edit_db_name: "atom-edit"
atom_replication_ro_db_name: "atom-ro"

atom_replication_ro_backup_tables:
  - access_log
  - clipboard_save
  - clipboard_save_item

# AtoM source paths
atom_replication_edit_path: "/usr/share/nginx/atom-edit"
atom_replication_ro_path: "/usr/share/nginx/atom-ro"

# Delete read-only db clipboard save items that reference slugs which no longer exist (Optional)
atom_replication_clipboard_delete_obsolete_items: True

# Services to be restarted on AtoM read-only host after replication
atom_replication_ro_nginx_restart_services:
  - "memcached"
  - "php-7.4fpm"
  - "atom-worker-ro"
  - "atom-worker-edit"

# Symfony commands to run on AtoM read-only host after replication
# as nginx user and {{ atom_replication_ro_path }} path
atom_replication_ro_nginx_symfony_commands:
  - "cc"
  - "tools:expire-data --older-than=$(date +'%Y-%m-%d' -d '-30 days') clipboard,job,access_log -f"
```

## Prepare the requirements file and download roles:

Assuming you are using a requirements.yml file for the roles in your ansible environment, you need to add:

```
- src: "https://github.com/artefactual-labs/ansible-atom-replication"
  version: "main"
  name: "artefactual.ansible-atom-replication
```

And download the roles with:

```
ansible-galaxy install -f -p roles -r requirements.yml
```

## Create the install playbook

You can download directly from [here](https://raw.githubusercontent.com/artefactual-labs/ansible-atom-replication/main/files/mgt.replication-aph-role.yml)

## Run the playbook

Run the playbook using the command:

```
ansible-playbook mgt.replication-aph-role.yml -e atom_replication_ansible_remote_server=atom-nginx -t install-replication
```

In case you want to use a different config file, you can append: `-e atom_replication_config=YOUR_FILE`

## Run replication by hand from `atom-nginx`

If you want to run the replication directly on the server, you need:

* ssh the server
* Move to the replication directory (`/usr/share/nginx/atom-replication`)
* Run the `site-replication.sh` script
