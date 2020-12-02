# lookup SSH public keys by name
data "ibm_is_ssh_key" "ssh_pub_key" {
  name = "${var.ssh_key_name}"
}

# lookup compute profile by name
data "ibm_is_instance_profile" "instance_profile" {
  name = "${var.instance_profile}"
}

# create a random password if we need it
resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

# lookup image name for a custom image in region if we need it
data "ibm_is_image" "tmos_custom_image" {
  name = "${var.tmos_image_name}"
}

locals {
  # use the public image if the name is found
  public_image_map = {
    bigip-14-1-2-6-0-0-2-all-1slot = {
      "us-south" = "r006-544557f5-bfa8-4fd0-a61a-bc647b593ae3"
      "us-east"  = "r014-00ded4bb-3abb-43ac-8d2e-16f4a9619889"
      "eu-gb"    = "r018-265c085a-a86b-4ca8-81f8-59b0cc3b7cda"
      "eu-de"    = "r010-a7b2bdcd-37b5-4b12-90a1-2373817c21bf"
      "jp-tok"   = "r022-176ff438-b0b8-4ee7-b152-08fd6746a9fe"
      "au-syd"   = "r026-65356d52-3014-4cfd-bdd9-74de225881e2"
    }
    bigip-14-1-2-6-0-0-2-ltm-1slot = {
      "us-south" = "r006-ae15ef68-82cf-4229-918b-fab9c5639e0a"
      "us-east"  = "r014-c42287ca-9b4e-4c5d-bfa4-52de59ffea06"
      "eu-gb"    = "r018-369df1fd-ce9d-4abf-b7dc-d6db59399b27"
      "eu-de"    = "r010-7c5d3ccf-f455-4408-911c-87f2908569d0"
      "jp-tok"   = "r022-3440a5f1-a21e-4e02-b32c-fce7fe6783b3"
      "au-syd"   = "r026-69355b10-86e9-43f4-9736-4ad10d5752f5"
    }
    bigip-15-1-0-4-0-0-6-all-1slot = {
      "us-south" = "r006-45627a8c-7aed-4bb6-8ceb-8988f6b89a06"
      "us-east"  = "r014-d9769a36-bc2d-41e1-aeb0-835e1f799f8e"
      "eu-gb"    = "r018-efcf8bdc-d4e2-4ad1-aa04-f485be0c1c40"
      "eu-de"    = "r010-8019c15f-8057-439c-940f-1ae95beaf322"
      "jp-tok"   = "r022-f0c33402-4152-4325-987c-02599c430a6d"
      "au-syd"   = "r026-21db3710-2d47-4f8b-b05d-6e52415377c1"
    }
    bigip-15-1-0-4-0-0-6-ltm-1slot = {
      "us-south" = "r006-bd24a8f4-ff18-4a79-9356-536183447965"
      "us-east"  = "r014-54b9a7fa-a002-4334-b774-a64df3284423"
      "eu-gb"    = "r018-fbe6ecdd-c9c9-4318-862f-b0d8a4e8f284"
      "eu-de"    = "r010-ed6f2e7d-334e-497e-a9f2-078e8906bc39"
      "jp-tok"   = "r022-81a4a3fc-d726-4da2-befa-24ecf3cd8db8"
      "au-syd"   = "r026-408b1f8e-830c-4fb8-98a2-014f015e85df"
    }
  }
}

locals {
  # set the user_data YAML template for each license type
  license_map = {
    "none"        = "${file("${path.module}/user_data_no_license.yaml")}"
    "byol"        = "${file("${path.module}/user_data_byol_license.yaml")}"
    "regkeypool"  = "${file("${path.module}/user_data_regkey_pool_license.yaml")}"
    "utilitypool" = "${file("${path.module}/user_data_utility_pool_license.yaml")}"
  }
}

locals {
  # custom image takes priority over public image
  image_id = data.ibm_is_image.tmos_custom_image.id == null ? lookup(local.public_image_map[var.tmos_image_name], var.region) : data.ibm_is_image.tmos_custom_image.id
  # public image takes priority over custom image
  # image_id = lookup(lookup(local.public_image_map, var.tmos_image_name, {}), var.region, data.ibm_is_image.tmos_custom_image.id)
  template_file = lookup(local.license_map, var.license_type, local.license_map["none"])
  # user admin_password if supplied, else set a random password
  admin_password = var.tmos_admin_password == "" ? random_password.password.result : var.tmos_admin_password
  # set user_data YAML values or else set them to null for templating
  phone_home_url          = var.phone_home_url == "" ? "null" : var.phone_home_url
  byol_license_basekey    = var.byol_license_basekey == "none" ? "null" : var.byol_license_basekey
  license_host            = var.license_host == "none" ? "null" : var.license_host
  license_username        = var.license_username == "none" ? "null" : var.license_username
  license_password        = var.license_password == "none" ? "null" : var.license_password
  license_pool            = var.license_pool == "none" ? "null" : var.license_pool
  license_sku_keyword_1   = var.license_sku_keyword_1 == "none" ? "null" : var.license_sku_keyword_1
  license_sku_keyword_2   = var.license_sku_keyword_2 == "none" ? "null" : var.license_sku_keyword_2
  license_unit_of_measure = var.license_unit_of_measure == "none" ? "null" : var.license_unit_of_measure
}

data "template_file" "user_data" {
  template = local.template_file
  vars = {
    tmos_admin_password     = local.admin_password
    tmos_license_basekey    = local.byol_license_basekey
    license_host            = local.license_host
    license_username        = local.license_username
    license_password        = local.license_password
    license_pool            = local.license_pool
    license_sku_keyword_1   = local.license_sku_keyword_1
    license_sku_keyword_2   = local.license_sku_keyword_2
    license_unit_of_measure = local.license_unit_of_measure
    phone_home_url          = local.phone_home_url
    template_source         = var.template_source
    template_version        = var.template_version
    zone                    = data.ibm_is_subnet.f5_managment_subnet.zone
    vpc                     = data.ibm_is_subnet.f5_managment_subnet.vpc
    app_id                  = var.app_id
  }
}

# create compute instance
resource "ibm_is_instance" "f5_ve_instance" {
  name    = var.instance_name
  image   = local.image_id
  profile = data.ibm_is_instance_profile.instance_profile.id
  resource_group = data.ibm_is_subnet.f5_managment_subnet.resource_group
  primary_network_interface {
    name            = "management"
    subnet          = data.ibm_is_subnet.f5_managment_subnet.id
    security_groups = [ibm_is_security_group.f5_open_sg.id]
  }
  dynamic "network_interfaces" {
    for_each = local.secondary_subnets
    content {
      name            = format("data-1-%d", (network_interfaces.key + 1))
      subnet          = network_interfaces.value
      security_groups = [ibm_is_security_group.f5_open_sg.id]
    }

  }
  vpc        = data.ibm_is_subnet.f5_managment_subnet.vpc
  zone       = data.ibm_is_subnet.f5_managment_subnet.zone
  keys       = [data.ibm_is_ssh_key.ssh_pub_key.id]
  user_data  = data.template_file.user_data.rendered
  depends_on = [ibm_is_security_group_rule.f5_allow_outbound]
  timeouts {
    create = "60m"
    delete = "120m"
  }
}

# create floating IP for management access
#resource "ibm_is_floating_ip" "f5_management_floating_ip" {
#  name   = "f0-${random_uuid.namer.result}"
#  target = ibm_is_instance.f5_ve_instance.primary_network_interface.0.id
#  resource_group = data.ibm_is_subnet.f5_managment_subnet.resource_group
#  timeouts {
#    create = "60m"
#    delete = "60m"
#  }
#}

# create 1:1 floating IPs to vNICs - Not supported by IBM yet
#resource "ibm_is_floating_ip" "f5_data_floating_ips" {
#  count = length(local.secondary_subnets)
#  name   = format("f%d-%s", (count.index+1), random_uuid.namer.result)
#  target = ibm_is_instance.f5_ve_instance.network_interfaces[count.index].id
#}

output "resource_name" {
  value = ibm_is_instance.f5_ve_instance.name
}

output "resource_status" {
  value = ibm_is_instance.f5_ve_instance.status
}

output "VPC" {
  value = ibm_is_instance.f5_ve_instance.vpc
}

output "image_id" {
  value = local.image_id
}

output "instance_id" {
  value = ibm_is_instance.f5_ve_instance.id
}

output "profile_id" {
  value = data.ibm_is_instance_profile.instance_profile.id
}

#output "f5_shell_access" {
#  value = "ssh://root@${ibm_is_floating_ip.f5_management_floating_ip.address}"
#}

output "f5_phone_home_url" {
  value = var.phone_home_url
}
