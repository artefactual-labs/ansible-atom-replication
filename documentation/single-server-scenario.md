Single server scenario
======================

Let's call this server `all-in-one-server`.

* IP Address: 1.2.3.4
* ssh user: artefactual
* OS: Ubuntu 18
* edit site URL: https://edit.all-in-one-server.accesstomemory.org
* read-only site URL: https://ro.all-in-one-server.accesstomemory.org
* edit AtoM path: /usr/share/nginx/atom-edit
* read-only AtoM path: /usr/share/nginx/atom-ro
* edit database and ES index name: atom-edit
* read-only database and ES index name: atom-ro

The downloads and uploads directories for both AtoM sites are the same (symlinks on read-only site pointing to edit ones). 

For this replication, we want:

* Install the replication ansible environment on the server, at `/usr/share/nginx/atom-replication` directory
* schedule a daily replication at 3:23 AM, and send email notifications to: "my_email@example.com"
* Don't copy clipboard and access log tables
* Remove deleted items in clipboard. If the read-only clipboard (we are not copiying the clipboard from edit site on read-only) has any item that has been deleted in the replication, then remove it from clipboard table.
* The uploads and downloads directory are the same for edit and read-only sites (symlink) so we don't need a uploads/downloads synchronization
* Run the `php symfony cc` command
* Restart memcached, php-fpm and both AtoM workers

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

all-in-one-server	ansible_ssh_host=1.2.3.4	ansible_ssh_user=artefactual

```

## Replication config file at `host_vars/all-in-one-server/replication-config.yml`

When using the `install-replication` tag, the suggested install playbook looks for the replication-config.yml file in the following directories (the first found is the one that is used):

* `host_vars/all-in-one-server/replication-config.yml`
* `files/all-in-one-server/replication-config.yml`
* Any other file defined as extra-var with: `-e atom_replication_config=YOUR_FILE`

In this example, we are going to use the first option, so we need to create the following file:

```
---

# Servers (Ansible host field in Ansible inventory)
atom_replication_edit_atom_host: "all-in-one-server"
atom_replication_ro_atom_host: "all-in-one-server"
atom_replication_edit_mysql_host: "all-in-one-server"
atom_replication_ro_mysql_host: "all-in-one-server"
atom_replication_edit_es_host: "all-in-one-server"
atom_replication_ro_es_host: "all-in-one-server"


# Ansible ssh IP addresses/hostnames (Ansible ssh host in Ansible inventory)
atom_replication_edit_atom_ansible_host: "localhost"
atom_replication_ro_atom_ansible_host: "localhost"
atom_replication_ro_es_ansible_host: "localhost"
atom_replication_edit_es_ansible_host: "localhost"
atom_replication_ro_mysql_ansible_host: "localhost"
atom_replication_edit_mysql_ansible_host: "localhost"

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
atom_replication_ansible_remote_cron_weekday: "*"
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
  - "php-7.2fpm"
  - "atom-worker-ro"
  - "atom-worker-edit"

# Symfony commands to run on AtoM read-only host after replication
# as nginx user and {{ atom_replication_ro_path }} path
atom_replication_ro_nginx_symfony_commands:
  - "cc"
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
ansible-playbook mgt.replication-aph-role.yml -e atom_replication_ansible_remote_server=all-in-one-server -t install-replication
```

In case you want to use a different config file, you can append: `-e atom_replication_config=YOUR_FILE`

## Run replication by hand from `all-in-one-server`

If you want to run the replication directly on the server, you need:

* ssh the server
* Move to the replication directory (`/usr/share/nginx/atom-replication`)
* Run the `site-replication.sh` script
