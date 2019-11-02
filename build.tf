# configure the cocker provider
provider "docker" {
  host = "tcp://${var.docker_host}:2376"
}

resource "docker_network" "private_network" {
  name = "testnet"
    ipam_config { 
      subnet = "172.16.238.0/24"
      gateway = "172.16.238.1"
    }
}

# start redis
resource "docker_container" "redis" {
  image = "${docker_image.redis.latest}"
  name  = "redis"
  ports {
    internal = "6379"
    external = "6379"
  }
  networks_advanced {
    name = "testnet"
    ipv4_address = "172.16.238.10"
  }
  depends_on = [docker_network.private_network,docker_image.redis]
}

resource "docker_image" "redis" {
  name = "redis:latest"
}

# build app
resource "null_resource" "build" {
  provisioner "local-exec" {
    command = "docker build -t $DOCKER_IMAGE ."
    environment = {
      DOCKER_IMAGE = "${var.docker_image}"
    }
    interpreter = ["/bin/sh", "-c"]
  }
  depends_on = [docker_network.private_network,docker_container.redis]
}

# start app
resource "docker_container" "pizza" {
  image = "${var.docker_image}"
  name  = "pizza-app"
  ports {
    internal = "3000"
    external = "8081"
  }
  networks_advanced {
    name = "testnet"
    ipv4_address = "172.16.238.20"
  }
  depends_on = [docker_network.private_network,docker_container.redis,null_resource.build]
}

# test app
resource "null_resource" "test" {
  provisioner "local-exec" {
    command = "./test.sh"
    environment = {
      DOCKER_HOST = "${var.docker_host}"
    }
    interpreter = ["/bin/sh", "-c"]
  }
  depends_on = [docker_container.pizza]
}

# login to dockerhub
resource "null_resource" "dockerlogin" {
  provisioner "local-exec" {
    command = "docker login --username=$DOCKER_USER --password=$DOCKER_PASS"
    environment = {
      DOCKER_USER = "${var.docker_user}"
      DOCKER_PASS = "${var.docker_pass}"
    }
    interpreter = ["/bin/sh", "-c"]
  }
  depends_on = [null_resource.test]
}

# push to dockerhub
resource "null_resource" "dockerpush" {
  provisioner "local-exec" {
    command = "docker push $DOCKER_IMAGE:latest"
    interpreter = ["/bin/sh", "-c"]
    environment = {
      DOCKER_IMAGE = "${var.docker_image}"
    }
  }
  depends_on = [null_resource.dockerlogin]
}
