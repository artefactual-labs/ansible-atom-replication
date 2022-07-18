Role Name
=========

A brief description of the role goes here.

This role must be installed in the edit AtoM nginx server.


Requirements
------------

Any pre-requisites that may not be covered by Ansible itself or the role should be mentioned here. For instance, if the role uses the EC2 module, it may be a good idea to mention in this section that the boto package is required.

Role Variables
--------------

A description of the settable variables for this role should go here, including any variables that are in defaults/main.yml, vars/main.yml, and any variables that can/should be set via parameters to the role. Any variables that are read from other roles and/or the global scope (ie. hostvars, group vars, etc.) should be mentioned here as well.

Dependencies
------------

A list of other roles hosted on Galaxy should go here, plus any details in regards to parameters that may need to be set for other roles, or variables that are used from other roles.

Example Playbook
----------------

To deploy from your local computer on ansible remote host (nginx edit site recomended) use the following playbook:

```
---
- hosts:
        - "all:!localhost:!~.*-hyperv:!~.*-mysql:!~.*-es"
  vars:
    atom_replication_config: "replication-config.yml"

  pre_tasks:
    - name: "Include replication config file"
      include_vars: "{{ item }}"
      with_first_found:
        - "host_vars/{{ inventory_hostname }}/{{ atom_replication_config }}"
        - "files/{{ inventory_hostname }}/{{ atom_replication_config }}"
        - "{{ atom_replication_config }}"
      tags: always

  roles:

    - role: "artefactual.ansible-atom-replication"
      become: "yes"
      tags:
        - "atom-replication"
```

And run:

```
ansible-playbook -l aph-test-nginx mgt.replication-aph-role.yml -t install-replication
```

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: servers
      roles:
         - { role: username.rolename, x: 42 }

License
-------

BSD

Author Information
------------------

An optional section for the role authors to include contact information, or a website (HTML is not allowed).
