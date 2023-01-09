# Define IntServ group number

variable "group_number" {

  type = string

  default = "9"

}



## OpenStack credentials can be used in a more secure way by using

## cloud.yaml from https://private-cloud.informatik.hs-fulda.de/project/api_access/clouds.yaml/



# or by using env vars exported from openrc here,

# e.g., using 'export TF_VAR_os_password=$OS_PASSWORD'



# Define OpenStack credentials, project config etc.

locals {

  auth_url      = "https://private-cloud.informatik.hs-fulda.de:5000/v3"

  user_name     = "IntServ${var.group_number}"

  user_password = "stelipiswild"

  tenant_name   = "IntServ${var.group_number}"

  #network_name  = "IntServ${var.group_number}-net"

  router_name   = "IntServ${var.group_number}-router"

  image_name    = "Ubuntu 22.04 - Jammy Jellyfish - 64-bit - Cloud Based Image"

  flavor_name   = "m1.small"

  region_name   = "RegionOne"

}



# Define OpenStack provider

terraform {

required_version = ">= 0.14.0"

  required_providers {

    openstack = {

      source  = "terraform-provider-openstack/openstack"

      version = ">= 1.46.0"

    }

  }

}



# Configure the OpenStack Provider

provider "openstack" {

  user_name   = local.user_name

  tenant_name = local.tenant_name

  password    = local.user_password

  auth_url    = local.auth_url

  region      = local.region_name

  use_octavia = true

}







###########################################################################

#

# create keypair

#

###########################################################################



# import keypair, if public_key is not specified, create new keypair to use

resource "openstack_compute_keypair_v2" "terraform-keypair" {

  name       = "ssh-pub"

  public_key = file("~/.ssh/id_rsa.pub")

}







###########################################################################

#

# create security group

#

###########################################################################



resource "openstack_networking_secgroup_v2" "terraform-secgroup" {

  name        = "EasyPassSecurity"

  description = "Portfreigaben"

}



resource "openstack_networking_secgroup_rule_v2" "terraform-secgroup-rule-http" {

 direction         = "ingress"

 ethertype         = "IPv4"

 protocol          = "tcp"

 port_range_min    = 80

 port_range_max    = 80

  remote_ip_prefix  = "0.0.0.0/0"

 security_group_id = openstack_networking_secgroup_v2.terraform-secgroup.id

}



resource "openstack_networking_secgroup_rule_v2" "terraform-secgroup-rule-python" {

  direction         = "ingress"

  ethertype         = "IPv4"

  protocol          = "tcp"

  port_range_min    = 5000

  port_range_max    = 5000

  remote_ip_prefix  = "0.0.0.0/0"

  security_group_id = openstack_networking_secgroup_v2.terraform-secgroup.id

}





resource "openstack_networking_secgroup_rule_v2" "terraform-secgroup-rule-ping" {

  direction         = "ingress"

  ethertype         = "IPv4"

  protocol          = "icmp"

  port_range_min    = "0"

  port_range_max    = "0"

  remote_ip_prefix  = "0.0.0.0/0"

  security_group_id = openstack_networking_secgroup_v2.terraform-secgroup.id

  }





resource "openstack_networking_secgroup_rule_v2" "terraform-secgroup-rule-ssh" {

  direction         = "ingress"

  ethertype         = "IPv4"

  protocol          = "tcp"

  port_range_min    = 22

  port_range_max    = 22

  #remote_ip_prefix  = "0.0.0.0/0"

  security_group_id = openstack_networking_secgroup_v2.terraform-secgroup.id

}





###########################################################################

#

# create network

#

###########################################################################



resource "openstack_networking_network_v2" "terraform-network-1" {

  name           = "Netzwerk1"

  admin_state_up = "true"

}



resource "openstack_networking_subnet_v2" "terraform-subnet-1" {

  name       = "Subnetz1"

  network_id = openstack_networking_network_v2.terraform-network-1.id

  cidr       = "192.168.1.0/24"

  ip_version = 4

}



data "openstack_networking_router_v2" "router-1" {

  name = local.router_name

}



resource "openstack_networking_router_interface_v2" "router_interface_1" {

  router_id = data.openstack_networking_router_v2.router-1.id

  subnet_id = openstack_networking_subnet_v2.terraform-subnet-1.id

}







###########################################################################

#

# create instances

#

###########################################################################



resource "openstack_compute_instance_v2" "terraform-instance-1" {

  name              = "Webserver1"

  image_name        = local.image_name

  flavor_name       = local.flavor_name

  key_pair          = openstack_compute_keypair_v2.terraform-keypair.name

  security_groups   = [openstack_networking_secgroup_v2.terraform-secgroup.name]



  depends_on = [openstack_networking_subnet_v2.terraform-subnet-1]



  network {

    uuid = openstack_networking_network_v2.terraform-network-1.id

  }



  user_data = <<-EOF

	#!/bin/bash

	now=$(date +"%T")

	echo "$now : Init started!" > /home/ubuntu/logfile_init.txt



	now=$(date +"%T")

	echo "$now : Starting Updating Packages!" >> /home/ubuntu/logfile_init.txt



	apt-get update



	now=$(date +"%T")

	echo "$now : Finished Updating Packages!" >> /home/ubuntu/logfile_init.txt



	now=$(date +"%T")

	echo "$now : Starting Installing Dependencies!" >> /home/ubuntu/logfile_init.txt



	apt-get -y install python3

	apt-get -y install python3-flask

	apt-get -y install python3-pip

	apt-get -y install build-essential python3-dev



	now=$(date +"%T")

	echo "$now : Finished Installing Dependencies!" >> /home/ubuntu/logfile_init.txt



	now=$(date +"%T")

	echo "$now : Starting Installing Pips!" >> /home/ubuntu/logfile_init.txt



	pip install uwsgi

	pip install zxcvbn



	now=$(date +"%T")

	echo "$now : Finished Installing Pips!" >> /home/ubuntu/logfile_init.txt



	now=$(date +"%T")

	echo "$now : Starting Cloning Git!" >> /home/ubuntu/logfile_init.txt



	cd /home/ubuntu

	git clone https://github.com/Veyris/password_web.git



	now=$(date +"%T")

	echo "$now : Finished Cloning Git!" >> /home/ubuntu/logfile_init.txt



	now=$(date +"%T")

	echo "$now : Starting Webserver with wsgi!" >> /home/ubuntu/logfile_init.txt

	cd password_web

	uwsgi --http :5000 --wsgi-file main.py --callable app



	now=$(date +"%T")

	echo "$now : WebserverRunning on Port 5000" >> /home/ubuntu/logfile_init.txt

  EOF

}



resource "openstack_compute_instance_v2" "terraform-instance-2" {

  name            = "Webserver2"

  image_name      = local.image_name

  flavor_name     = local.flavor_name

  key_pair        = openstack_compute_keypair_v2.terraform-keypair.name

  security_groups = [openstack_networking_secgroup_v2.terraform-secgroup.id]



  depends_on = [openstack_networking_subnet_v2.terraform-subnet-1]



  network {

    uuid = openstack_networking_network_v2.terraform-network-1.id

  }



  user_data = <<-EOF

	#!/bin/bash

	now=$(date +"%T")

	echo "$now : Init started!" > /home/ubuntu/logfile_init.txt



	now=$(date +"%T")

	echo "$now : Starting Updating Packages!" >> /home/ubuntu/logfile_init.txt



	apt-get update



	now=$(date +"%T")

	echo "$now : Finished Updating Packages!" >> /home/ubuntu/logfile_init.txt



	now=$(date +"%T")

	echo "$now : Starting Installing Dependencies!" >> /home/ubuntu/logfile_init.txt



	apt-get -y install python3

	apt-get -y install python3-flask

	apt-get -y install python3-pip

	apt-get -y install build-essential python3-dev



	now=$(date +"%T")

	echo "$now : Finished Installing Dependencies!" >> /home/ubuntu/logfile_init.txt



	now=$(date +"%T")

	echo "$now : Starting Installing Pips!" >> /home/ubuntu/logfile_init.txt



	pip install uwsgi

	pip install zxcvbn



	now=$(date +"%T")

	echo "$now : Finished Installing Pips!" >> /home/ubuntu/logfile_init.txt



	now=$(date +"%T")

	echo "$now : Starting Cloning Git!" >> /home/ubuntu/logfile_init.txt



	cd /home/ubuntu

	git clone https://github.com/Veyris/password_web.git



	now=$(date +"%T")

	echo "$now : Finished Cloning Git!" >> /home/ubuntu/logfile_init.txt



	now=$(date +"%T")

	echo "$now : Starting Webserver with wsgi!" >> /home/ubuntu/logfile_init.txt

	cd password_web

	uwsgi --http :5000 --wsgi-file main.py --callable app



	now=$(date +"%T")

	echo "$now : WebserverRunning on Port 5000" >> /home/ubuntu/logfile_init.txt

  EOF

}



resource "openstack_compute_instance_v2" "terraform-instance-3" {

  name              = "Logger"

  image_name        = local.image_name

  flavor_name       = local.flavor_name

  key_pair          = openstack_compute_keypair_v2.terraform-keypair.name

  security_groups   = [openstack_networking_secgroup_v2.terraform-secgroup.name]



  depends_on = [openstack_networking_subnet_v2.terraform-subnet-1]



  network {

    uuid = openstack_networking_network_v2.terraform-network-1.id

  }



  

}



###########################################################################

#

# create load balancer

#

###########################################################################

resource "openstack_lb_loadbalancer_v2" "lb_1" {

  vip_subnet_id = openstack_networking_subnet_v2.terraform-subnet-1.id

  name		 = "Loader"

}



resource "openstack_lb_listener_v2" "listener_1" {

  protocol        = "HTTP"

  protocol_port   = 80 #CHANGED

  loadbalancer_id = openstack_lb_loadbalancer_v2.lb_1.id

  connection_limit = 1024

}



resource "openstack_lb_pool_v2" "pool_1" {

  protocol    = "HTTP"

  lb_method   = "ROUND_ROBIN"

  listener_id = openstack_lb_listener_v2.listener_1.id

}



resource "openstack_lb_members_v2" "members_1" {

  pool_id = openstack_lb_pool_v2.pool_1.id



  member {

    address       = openstack_compute_instance_v2.terraform-instance-1.access_ip_v4

    protocol_port = 5000 #CHANGED

  }



  member {

    address       = openstack_compute_instance_v2.terraform-instance-2.access_ip_v4

    protocol_port = 5000 #CHANGED

  }

}



resource "openstack_lb_monitor_v2" "monitor_1" {

  

  pool_id        = openstack_lb_pool_v2.pool_1.id

  type           = "HTTP"

  delay          = 5

  timeout        = 5

  max_retries    = 3

  http_method    = "GET"

  url_path       = "/"

  expected_codes = 200



  depends_on = [openstack_lb_loadbalancer_v2.lb_1, openstack_lb_listener_v2.listener_1, openstack_lb_pool_v2.pool_1, openstack_lb_members_v2.members_1 ]

}



###########################################################################

#

# assign floating ip to logger

#

###########################################################################

resource "openstack_networking_floatingip_v2" "fip_2" {

  pool    = "public1"

}



resource "openstack_compute_floatingip_associate_v2" "fip_2" {

   floating_ip = "${openstack_networking_floatingip_v2.fip_2.address}"

   instance_id = "${openstack_compute_instance_v2.terraform-instance-3.id}"

}





###########################################################################

#

# assign floating ip to load balancer

#

###########################################################################

resource "openstack_networking_floatingip_v2" "fip_1" {

  pool    = "public1"

  port_id = openstack_lb_loadbalancer_v2.lb_1.vip_port_id

}



output "loadbalancer_vip_addr" {

  value = openstack_networking_floatingip_v2.fip_1

}



