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
      - docker.io
      - docker-compose
      {% else %}
      - docker
      - docker-compose
      {% endif %}
    - require:
      - pkg: install_docker_dependencies

docker_service:
  service.running:
    - name: docker
    - enable: True
    - require:
      - pkg: install_docker
