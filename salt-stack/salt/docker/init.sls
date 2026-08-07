# Salt State to install Docker and Docker Compose

install_docker_dependencies:
  pkg.installed:
    - names:
      {% if grains['os_family'] == 'Debian' %}
      - apt-transport-https
      - ca-certificates
      - curl
      - software-properties-common
      - gnupg
      {% elif grains['os_family'] == 'RedHat' %}
      - yum-utils
      - device-mapper-persistent-data
      - lvm2
      {% endif %}

install_docker:
  pkg.installed:
    - names:
      {% if grains['os_family'] == 'Debian' %}
      - docker-ce
      - docker-ce-cli
      - containerd.io
      - docker-compose-plugin
      {% else %}
      - docker
      - docker-compose
      {% endif %}
    - require:
      - pkg: install_docker_dependencies

docker_compose_symlink:
  file.symlink:
    - name: /usr/local/bin/docker-compose
    - target: /usr/libexec/docker/cli-plugins/docker-compose
    - force: True
    - require:
      - pkg: install_docker

docker_group:
  group.present:
    - name: docker
    - system: True

{% set docker_user = salt['pillar.get']('ecom:user', 'prakritidev881') %}
docker_user_group:
  user.present:
    - name: {{ docker_user }}
    - groups:
      - docker
    - remove_groups: False
    - require:
      - group: docker_group

docker_service:
  service.running:
    - name: docker
    - enable: True
    - require:
      - pkg: install_docker
