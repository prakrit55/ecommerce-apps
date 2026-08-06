# Salt State to configure environment and deploy ecom application via Docker Compose

{% set app_dir = salt['pillar.get']('ecom:app_dir', '/opt/ecom') %}

# Ensure application base directory exists
ecom_base_dir:
  file.directory:
    - name: {{ app_dir }}
    - user: root
    - group: root
    - mode: 755
    - makedirs: True

# Recurse and sync docker-compose config files
sync_docker_compose_config:
  file.recurse:
    - name: {{ app_dir }}/docker-compose
    - source: salt://ecom/files/docker-compose-config
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - include_empty: True
    - clean: False

# Manage templated .env file
ecom_env_file:
  file.managed:
    - name: {{ app_dir }}/docker-compose/.env
    - source: salt://ecom/files/.env.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 600
    - require:
      - file: ecom_base_dir

{% set repo_dir = salt['pillar.get']('ecom:repo_dir', '') %}

# Sync or link source code folders for docker build context
{% for folder in [
  'product-catalog-code',
  'product-inventory-src',
  'shipping-and-handling-src',
  'contact-support-team-src',
  'order-management-code',
  'ecommerce-ui-code'
] %}
sync_source_{{ folder }}:
  {% if repo_dir %}
  file.symlink:
    - name: {{ app_dir }}/{{ folder }}
    - target: {{ repo_dir }}/{{ folder }}
    - force: True
  {% else %}
  file.recurse:
    - name: {{ app_dir }}/{{ folder }}
    - source: salt://ecom/files/{{ folder }}
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - include_empty: True
    - clean: False
  {% endif %}
{% endfor %}

# Deploy the application using Docker Compose
deploy_ecom_app:
  cmd.run:
    - name: docker-compose up -d --build
    - cwd: {{ app_dir }}/docker-compose
      {% for folder in [
        'product-catalog-code',
        'product-inventory-src',
        'shipping-and-handling-src',
        'contact-support-team-src',
        'order-management-code',
        'ecommerce-ui-code'
      ] %}
      - file: sync_source_{{ folder }}
      {% endfor %}
