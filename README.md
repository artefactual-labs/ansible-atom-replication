ansible-atom-replication
========================

This role allows system adminstrators to deploy, configure and reconfigure an ansible environment on a server (called `ansible-run-server`) that will be used to run the AtoM replication process. AtoM replication can be used to manage a 2-site AtoM deployment model - one public-facing read only site for public users, with content replicated from an internal read/write edit site for staff, which can be kept behind a firewall. Public login can also be fully disabled in the public site.

In addition to enhancing security, this 2-site deployment model can also increase performance and scalability, as well as give archivists more control over when new records without a publication status (such as authority records) are made publicly discoverable.

The `ansible-run-server` can be:

* Your computer.
* Any external server.
* One of the AtoM servers, but *it is recommended to be deployed on the server that runs the AtoM read-only service*.

(See `ansible-run-server` definition in the next section)

**Table of Contents**

- [Dictionary of terms](#dictionary-of-terms)
- [Scenarios](#scenarios)
- [Requirements](#requirements)
- [Role variables](#role-variables)
- [Dependencies](#dependencies)
- [Playbook to install the ansible environment on the ansible-run-server](#playbook-to-install-the-ansible-environment-on-the-ansible-run-server)
- [License](#license)
- [Author Information](#author-information)

Dictionary of terms
-------------------

The following terms will be used in this document:

* `ansible-run-server`: Server where we are going to deploy the ansible environment to run the replication. 
* `edit-atom-site`: AtoM site that will be replicated.
* `read-only-atom-site`: This is the AtoM destination site that will be replica of the `edit-atom-site`. It doesn't matter if this is a read-only AtoM site (login disabled), but this is the name we are going to use.
* `edit-atom-host`: This is the AtoM server that hosts the `edit-atom-site`.
* `read-only-atom-host`: This is the AtoM server that hosts the `read-only-atom-site`.
* `edit-elasticsearch-host`: Elasticsearch server that contains the `edit-atom-site` index.
* `read-only-elasticsearch-host`: Elasticsearch server that contains the `read-only-atom-site` index.
* `edit-mysql-host`: MySQL server that provides the `edit-atom-site` database.
* `read-only-mysql-host`: MySQL server that provides the `read-only-atom-site` database.

Scenarios
---------

The role can be used in different scenarios, for instance:

* All the edit and read-only hosts are the same server: Single server with AtoM, elasticsearch and MySQL servers with the two AtoM sites configured.
* Two servers scenario: One server as `edit-atom-host`, `edit-elasticsearch-host` and `edit-mysql-host` server, and the second server as `read-only-*-host`.
* Six servers scenario: Each `edit-atom-host`, `edit-elasticsearch-host`, `edit-mysql-host`, `read-only-atom-host`, `read-only-elasticsearch-host`, `read-only-mysql-host` is a different server.
* Any `edit-atom-host`, `edit-elasticsearch-host`, `edit-mysql-host`, `read-only-atom-host`, `read-only-elasticsearch-host`, `read-only-mysql-host` combination.

A dedicated documentation for some sample scenarios can be found here:

1. [Single Server with all services and two AtoM sites](documentation/single-server-scenario.md)
2. [Two servers with their own nginx, elasticsearch and MySQL services and a site on every server](documentation/two-servers-scenario.md)
3. [Three servers: nginx server with the two AtoM sites, a MySQL server for both sites and an Elasticsearch server for both sites](documentation/three-servers-scenario.md)

Requirements
------------

The role has been tested on AtoM 2.6 and AtoM 2.7 servers. 

* ssh connections to all servers in scenario and sudo privileges

The OS tested are:

* Ubuntu 18
* Ubuntu 20
* CentOS 7

You need ansible >= 2.10. The recommended version is 2.12.5. It is because the role uses the `mysql_query` module and it doesn't exist in ansible<=2.9. The following collections must be installed:

* ansible.posix
* community.general
* community.mysql

The MySQL servers must be configured to allow the passwordless connection from localhost and root user using an UNIX socket file.

Your ansible.cfg and/or your ssh settings must allow the ssh agent forwarding because several tasks are delegated to other servers and it is assumed that the feature is enabled. For instance you can append to your `ssh_args` variable at `ansible.cfg` the string: `-o ForwardAgent=yes`

Role Variables
--------------

All variables which can be overridden are stored in [defaults/main.yml](defaults/main.yml) file as well as in table below.

| Name           | Default Value | Description                        |
| -------------- | ------------- | -----------------------------------|
| `atom_replication_edit_atom_host` | localhost | AtoM server hostname in `ansible-run-server` ansible inventory with the site that will be used as source of the replication  |
| `atom_replication_ro_atom_host` | localhost |  AtoM server hostname in `ansible-run-server` ansible inventory with the site that will be used as destination of the replication. From `ansible-run-server` point of view. It doesn't matter if this is a read-only AtoM site (login disabled) |
| `atom_replication_edit_mysql_host` | localhost  | MySQL server hostname in `ansible-run-server` ansible inventory with the database used as source of the replication |
| `atom_replication_ro_mysql_host` | localhost  | MySQL server hostname in `ansible-run-server` ansible inventory with the database used as destination of the replication |
| `atom_replication_edit_es_host` | localhost | Elasticsearch server hostname in `ansible-run-server` ansible inventory with the index used as source of the replication |
| `atom_replication_ro_es_host` | localhost | Elasticsearch server hostname in `ansible-run-server` ansible inventory with the index used as destination of the replication |
| `atom_replication_edit_atom_ansible_user` | artefactual | Ansible ssh username used for the `atom_replication_edit_atom_host` host |
| `atom_replication_ro_atom_ansible_user` | artefactual | Ansible ssh username used for the `atom_replication_ro_atom_host` host |
| `atom_replication_edit_mysql_ansible_user` | artefactual  | Ansible ssh username used for the `atom_replication_edit_mysql_host` host |
| `atom_replication_ro_mysql_ansible_user` | artefactual  | Ansible ssh username used for the `atom_replication_ro_mysql_host` host |
| `atom_replication_edit_es_ansible_user` | artefactual  | Ansible ssh username used for the `atom_replication_edit_es_host` host |
| `atom_replication_ro_es_ansible_user` | artefactual  | Ansible ssh username used for the `atom_replication_ro_es_host` host |
| `atom_replication_edit_atom_ansible_host` | localhost | Ansible ssh hostname (can be a hostname, FQDN or an IP address) used for the `atom_replication_edit_atom_host` host. The default value is `localhost` because the recommended `ansible-run-server` is the `atom_replication_edit_atom_host` server |
| `atom_replication_ro_atom_ansible_host` | 1.1.1.1 | Ansible ssh hostname (can be a hostname, FQDN or an IP address) used for the `atom_replication_ro_atom_host` host. The default value must be changed in config file with the hostname, FQDN or IP address to connect that server from the `ansible-run-server` server |
| `atom_replication_edit_mysql_ansible_host` | 1.1.1.1 | Ansible ssh hostname (can be a hostname, FQDN or an IP address) used for the `atom_replication_edit_mysql_host` host. The default value must be changed in config file with the hostname, FQDN or IP address to connect that server from the `ansible-run-server` server |
| `atom_replication_ro_mysql_ansible_host` | 1.1.1.1 | Ansible ssh hostname (can be a hostname, FQDN or an IP address) used for the `atom_replication_ro_mysql_host` host. The default value must be changed in config file with the hostname, FQDN or IP address to connect that server from the `ansible-run-server` server |
| `atom_replication_edit_es_ansible_host` | 1.1.1.1 | Ansible ssh hostname (can be a hostname, FQDN or an IP address) used for the `atom_replication_edit_es_host` host. The default value must be changed in config file with the hostname, FQDN or IP address to connect that server from the `ansible-run-server` server |
| `atom_replication_ro_es_ansible_host` | 1.1.1.1 | Ansible ssh hostname (can be a hostname, FQDN or an IP address) used for the `atom_replication_edit_ro_host` host. The default value must be changed in config file with the hostname, FQDN or IP address to connect that server from the `ansible-run-server` server |
| `atom_replication_ansible_cfg_timeout` | 60 | Timeout variable in ansible.cfg (ansible-run-server) |
| `atom_replication_edit_mysql_snapshots_dir` | /var/artefactual/replication-snapshots | Temporary directory on `atom_replication_edit_mysql_host` for MySQL backups |
| `atom_replication_ro_mysql_snapshots_dir` | /var/artefactual/replication-snapshots | Temporary directory on `atom_replication_ro_mysql_host` for MySQL backups |
| `atom_replication_edit_es_snapshots_dir` | /var/artefactual/replication-snapshots | Temporary directory on `atom_replication_edit_es_host` for Elasticsearch backups |
| `atom_replication_ro_es_snapshots_dir` | /var/artefactual/replication-snapshots | Temporary directory on `atom_replication_es_mysql_host` for Elasticsearch backups |
| `atom_replication_ansible_host_snapshots_dir` | `{{ atom_replication_ansible_remote_path }}/replication`  | Temporary directory for backups on `ansible-run-server` server |
| `atom_replication_snapshot_mysql_user` | mysql | User for MySQL snapshots files |
| `atom_replication_snapshot_mysql_group` | mysql | Group for MySQL snapshots files |
| `atom_replication_snapshot_es_user` | elasticsearch | User for Elasticsearch snapshots files |
| `atom_replication_snapshot_es_group` | elasticsearch | Group for Elasticsearch snapshots files |
| `atom_replication_ansible_remote_server` | `{{ atom_replication_edit_atom_host }}`  | Hostname in your ansible local inventory for the server where the ansible environment is going to be installed (`ansible-run-server`). Only used with the `install-replication` tag, and additionaly we need to pass this variable as an extra-variable when running the role with the `install-replication` tag |
| `atom_replication_ansible_remote_user` | artefactual | Ansible user to run the playbook on `ansible-run-server`, it can be different than the ssh user in inventory to install the role in remote server. Only used with the `install-replication` tag |
| `atom_replication_ansible_remote_path` | /home/artefactual/atom-replication | Directory on the `ansible-run-server` where the replication ansible environment is going to be installed |
| `atom_replication_ansible_remote_cron_enabled` | False | Variable to enable the crontab job for the replication on the `ansible-run-server` server |
| `atom_replication_ansible_remote_cron_minute` | 0 | Minute field in the cron job to run the replication script. Only used when `atom_replication_ansible_remote_cron_enabled=True` |
| `atom_replication_ansible_remote_cron_hour` | 7 | Hour field in the cron job to run the replication script. Only used when `atom_replication_ansible_remote_cron_enabled=True` |
| `atom_replication_ansible_remote_cron_day` | * | Day field in the cron job to run the replication script. Only used when `atom_replication_ansible_remote_cron_enabled=True` |
| `atom_replication_ansible_remote_cron_month` | * | Month field in the cron job to run the replication script. Only used when `atom_replication_ansible_remote_cron_enabled=True` |
| `atom_replication_ansible_remote_cron_weekday` | 0 | Weekday field in the cron job to run the replication script. Only used when `atom_replication_ansible_remote_cron_enabled=True` |
| `atom_replication_ansible_remote_cron_name` | AtoM site replication | Cron job name to run the replication script. When using more than one replication script in the same `ansible-run-server`, please ensure it is different for every script. Only used when `atom_replication_ansible_remote_cron_enabled=True` |
| `atom_replication_ansible_remote_cron_user` | `{{ atom_replication_ansible_remote_user }}` | Cron job user to run the replication script. Only used when `atom_replication_ansible_remote_cron_enabled=True` |
| `atom_replication_ansible_remote_cron_file` | replicate-atom | Cron job filename to run the replication script. When using more than one replication script in the same `ansible-run-server`, please ensure it is different for every script. Only used when `atom_replication_ansible_remote_cron_enabled=True` |
| `atom_replication_ansible_remote_cron_mailto` | | Email address to sent the replication script output. Only used when `atom_replication_ansible_remote_cron_enabled=True` |
| `atom_replication_es_port` | 9200 | Elasticsearch tcp port used to connect to both elasticsearch servers |
| `atom_replication_edit_es_base_url_schema` | http | Base url schema for edit elasticsearch url |
| `atom_replication_ro_es_base_url_schema` | http | Base url schema for read-only elasticsearch url |
| `atom_replication_edit_es_base_url_host` | 127.0.0.1 | Base url host for edit elasticsearch url |
| `atom_replication_ro_es_base_url_host` | 127.0.0.1 | Base url host for read-only elasticsearch url |
| `atom_replication_edit_es_base_url` | {{ atom_replication_edit_es_base_url_schema }}://{{ atom_replication_edit_es_base_url_host }} | Elasticsearch edit base URL, by default it is built using the other 2 elasticsearch schema variables |
| `atom_replication_ro_es_base_url` | {{ atom_replication_ro_es_base_url_schema }}://{{ atom_replication_ro_es_base_url_host }} | Elasticsearch edit base URL, by default it is built using the other 2 elasticsearch schema variables |
| `atom_replication_edit_es_index` | atom-edit  | AtoM Elasticsearch index name on AtoM edit site |
| `atom_replication_ro_es_index` | atom-ro  | AtoM Elasticsearch index name on AtoM read-only site |
| `atom_replication_es_repo_name` | backup-repo | Elasticsearch repo name to take and restore the backups |
| `atom_replication_es_snapshot_name` | backup-repo | Elasticsearch snapshot name to take and restore the backups |
| `atom_replication_es_backup_repo_path` | /var/lib/elasticsearch/backup-repo | Elasticsearch repo path to take and restore the backups |
| `atom_replication_edit_db_name` | atom-edit | AtoM database name for the edit site |
| `atom_replication_ro_db_name` | atom-ro | AtoM database name for the read-only site |
| `atom_replication_edit_mysql_unix_socket` | `{{ '/var/lib/mysql/mysql.sock' if ansible_os_family == 'RedHat' else '/var/run/mysqld/mysqld.sock' }}` | Unix socket file to connect to the edit database server. It is used always on tasks that are delegated or running on the database server (localhost). The default value uses a conditional filter that sets the unix socket file depending on the Operative System |
| `atom_replication_ro_mysql_unix_socket` | `{{ '/var/lib/mysql/mysql.sock' if ansible_os_family == 'RedHat' else '/var/run/mysqld/mysqld.sock' }}` | Unix socket file to connect to the read-only database server. It is used always on tasks that are delegated or running on the database server (localhost). The default value uses a conditional filter that sets the unix socket file depending on the Operative System |
| `atom_replication_ro_backup_tables` | [] | List of tables on read-only database that are not going to be replaced with the replication process. The default value is an empty list |
| `atom_replication_edit_path` | /usr/share/nginx/atom-edit | AtoM directory on the edit AtoM server |
| `atom_replication_ro_path` | /usr/share/nginx/atom-ro | AtoM directory on the read-only AtoM server |
| `atom_replication_edit_downloads_path` | `{{ atom_replication_edit_path }}/downloads/` | Downloads directory on edit AtoM server that will be synchronized on the read-only AtoM server when `atom_replication_synchronize_downloads_dir=True`. This variable always must end in "/" character |
|`atom_replication_ro_downloads_path` | `{{ atom_replication_ro_path }}/downloads/` | Downloads directory on read-only AtoM server, this is the destination on the synchronization from the edit AtoM server downloads directory when `atom_replication_synchronize_downloads_dir=True`. This variable always must end in "/" character |
| `atom_replication_edit_uploads_path` | `{{ atom_replication_edit_path }}/uploads/` | Uploads directory on edit AtoM server that will be synchronized on the read-only AtoM server when `atom_replication_synchronize_uploads_dir=True`. This variable always must end in "/" character |
|`atom_replication_ro_uploads_path` | `{{ atom_replication_ro_path }}/uploads/` | Uploads directory on read-only AtoM server, this is the destination on the synchronization from the edit AtoM server uploads directory when `atom_replication_synchronize_uploads_dir=True`. This variable always must end in "/" character |
| `atom_replication_synchronize_downloads_dir` | False | Boolean variable that enables the synchronization of the downloads directories |
| `atom_replication_synchronize_uploads_dir` | False | Boolean variable that enables the synchronization of the uploads directories |
| `atom_replication_ro_nginx_user` | `{% if ansible_os_family == 'RedHat' %}nginx{% elif ansible_os_family == 'Debian' %}www-data{% endif %}` | Nginx user on the AtoM read-only  server. It is needed to run the php symfony commands |
| `atom_replication_restore_sitetitle` | False | When variable is set to True the role will change the siteTitle on the read-only database, using the `atom_replication_ro_sitetitle` value |
| `atom_replication_ro_sitetitle` | Read Only Site | String used as siteTitle in the setting_i18n table (read-only database) when `atom_replication_restore_sitetitle=True` |
| `atom_replication_synchronize_baseurl` | False | When not using the read-only base URL on the edit AtoM server, setting this variable as `True` the role will change the base URL on read-only site on all files in the downloads directory |
| `atom_replication_edit_dnsname` | http://edit.accesstomemory.org/ | String that will be replaced by the `atom_replication_ro_dnsname` string on the AtoM read-only downloads files when `atom_replication_synchronize_baseurl=True` |
| `atom_replication_ro_dnsname` | http://ro.accesstomemory.org/ | String that replaces the `atom_replication_edit_dnsname` string on the AtoM read-only downloads files when `atom_replication_synchronize_baseurl=True` |
| `atom_replication_synchronize_clipboard` | False | Boolean variable to synchronize the edit site clipboard on the read-only site. As the user identificators can be different in both databases, some steps were needed in the role task |
| `atom_replication_clipboard_delete_obsolete_items` | False | Delete read-only db clipboard save items that reference slugs which no longer exist. This variable is not related to `atom_replication_synchronize_clipboard`, both variables are related to different task files |
| `atom_replication_ro_nginx_restart_services` | [ memcached ] | List of service names that will be restarted at the end of the role on the AtoM read-only server. It is recommended to have at least the memcached and php-fpm services to clean the cache |
| `atom_replication_ro_nginx_symfony_commands` | [ cc ] | List of php symfony commands to be run at the end of the role. It is recommended to have at least the `cc` command |
| `atom_replication_email_notification_enabled`| False | Boolean variable that enables the email notification. Usefull when not running the replication using a cronjob and you desire to send an email notificacion with status and ansible log. The next variables are not used on crontab email notification |
| `atom_replication_email_notification_host` | localhost | Mail server. This must be a FQDN or IP address |
| `atom_replication_email_notification_port` | 25 | Mail server port. This must be a valid integer between 1 and 65534 |
| `atom_replication_email_notification_subject` | Ansible replication playbook log | Notification email's subject. The playbook adds automatically the playbook status (`ERROR:` or `SUCCESS:`) at the beginning) |
| `atom_replication_email_notification_body` | Find the replication playbook log in the attached file | Notification email's body |
| `atom_replication_email_notification_secure` | try | See secure option at [ansible mail module doc](https://docs.ansible.com/ansible/latest/collections/community/general/mail_module.html) |
| `atom_replication_email_notification_sender` | root | The email-address the mail is sent from. May contain address and phrase |
| `atom_replication_email_notification_to` | test@example.com | The email-address(es) the mail is being send to. This is a list, which may contain address and phrase portions |
| `atom_replication_email_notification_cc` | [] | The email-address(es) the mail is being copied to. This is a list, which may contain address and phrase portions |
| `atom_replication_email_notification_subtype` | plain | The minor mime type, can be either `plain` or `html` |
| `atom_replication_email_notification_username` | Not used | If SMTP requires username (Optional) |
| `atom_replication_email_notification_password` | Not used | If SMTP requires password (Optional) |

Dependencies
------------

This role doesn't have any addtional dependencies.

Playbook to install the ansible environment on the ansible-run-server
---------------------------------------------------------------------

The following playbook installs the ansible environment on the ansible-run-server ([raw file here](https://raw.githubusercontent.com/artefactual-labs/ansible-atom-replication/main/files/mgt.replication-aph-role.yml)):

```
---
# Read the config file from localhost and make sure the install-replication tag is used
- hosts: "localhost"
  vars:
    atom_replication_config: "replication-config.yml"
  pre_tasks:
    - name: "Include replication config file"
      include_vars: "{{ item }}"
      with_first_found:
        - "host_vars/{{ atom_replication_ansible_remote_server }}/{{ atom_replication_config }}"
        - "files/{{ atom_replication_ansible_remote_server }}/{{ atom_replication_config }}"
        - "{{ atom_replication_config }}"
      tags: always

    - name: "Make sure the install-replication tag is used"
      fail:
        msg: "Please, use the the install-replication tag. Exiting.."
      failed_when: "'install-replication' not in hostvars['localhost']['ansible_run_tags']"
      tags: always

- hosts:
        - "{{ atom_replication_ansible_remote_server }}"
        - "{{ hostvars['localhost']['atom_replication_ro_es_host'] }}"
        - "{{ hostvars['localhost']['atom_replication_edit_es_host'] }}"
        - "!localhost"
  vars:
    atom_replication_config: "replication-config.yml"


# We need to run the role on the following hosts because:
#    * atom_replication_ansible_remote_server: To install the replication ansible script and files
#    * atom_replication_*_es_host: To configure the backup repo
- hosts:
        - "{{ atom_replication_ansible_remote_server }}"
        - "{{ hostvars['localhost']['atom_replication_ro_es_host'] }}"
        - "{{ hostvars['localhost']['atom_replication_edit_es_host'] }}"
        - "!localhost"
  vars:
    atom_replication_config: "replication-config.yml"

  pre_tasks:

    - name: "Include replication config file"
      include_vars: "{{ item }}"
      with_first_found:
        - "host_vars/{{ atom_replication_ansible_remote_server }}/{{ atom_replication_config }}"
        - "files/{{ atom_replication_ansible_remote_server }}/{{ atom_replication_config }}"
        - "{{ atom_replication_config }}"
      tags: "always"

  roles:
    - role: "artefactual.ansible-atom-replication"
      become: "yes"
      tags:
        - "atom-replication"
```

The above playbook requires:

* The ansible inventory contains all the atom, elasticsearch and MySQL servers
* You must pass as extra-variable the `atom_replication_ansible_remote_server` when running the playbook
* You must use the `install-replication` tag when running the playbook (or it will be aborted by a pre-task)
* You have prepared the `atom_replication_config` in any of the following paths (precedence order: the first find is the one used):
	- `host_vars/{{ atom_replication_ansible_remote_server }}/{{ atom_replication_config }}`
	- `files/{{ atom_replication_ansible_remote_server }}/{{ atom_replication_config }}"`
	- Or any relative path defined as extra variable for `{{ atom_replication_config }}`, eg: `my_replication_files/my_replication_file.yml`

Run the playbook with something like this:

```
ansible-playbook -e atom_replication_ansible_remote_server=MY_ATOM_REPLICATION_REMOTE_SERVER  -t install-replication
```

For more details see the following 3 sample scenarios:

1. [Single Server with all services and two AtoM sites](documentation/single-server-scenario.md)
2. [Two servers with their own nginx, elasticsearch and MySQL services and a site on every server](documentation/two-servers-scenario.md)
3. [Three servers: nginx server with the two AtoM sites, a MySQL server for both sites and an Elasticsearch server for both sites](documentation/three-servers-scenario.md)

License
-------

AGPL-3.0.

Author Information
------------------

Artefactual Systems Inc.
https://www.artefactual.com
