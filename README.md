# F5 Networks BIG-IP™ Virtual Edition Instance Creation using Catalog image

This directory contains the Terraform module to create BIG-IP™ VPC Gen2 instances using catalog input from the user.

Use this template to create BIG-IP™ Virtual Edition instances using catalog image from your IBM Cloud account in IBM Cloud [VPC Gen2](https://cloud.ibm.com/vpc-ext/overview) by using Terraform or IBM Cloud Schematics.  Schematics uses Terraform as the infrastructure-as-code engine.  With this template, you can create and manage infrastructure as a single unit as follows. For more information about how to use this template, see the IBM Cloud [Schematics documentation](https://cloud.ibm.com/docs/schematics).

This template requires that the F5 TMOS™ qcow2 images be patched including the IBM VPC Gen2 cloudinit config and the full complement of tmos-cloudinit modules. The template also requires the f5-declarative-onboarding AT extension version 1.16.0 or greater be included in the patched image.

This Schematics template submits cloudinit user-data which utilizes the F5 Declarative Onboarding extension. Documentation for this extension can be found at:

[F5 Cloud Documentation for the F5 Declarative Onboarding Extension](https://clouddocs.f5.com/products/extensions/f5-declarative-onboarding/latest/)

In addition to installing and utilizing the Declarative Onboarding extension, the image onboarding process also installs recent versions of the F5 Application Services 3 and Telemetry Streaming extensions. Documentation of these extensions, and the use of their control plane API endpoints, can be found at:

[F5 Cloud Documentation for the F5 Application Services 3 Extension](https://clouddocs.f5.com/products/extensions/f5-appsvcs-extension/latest/)

[F5 Cloud Documentation for the F5 Telemetry Services Extension](https://clouddocs.f5.com/products/extensions/f5-telemetry-streaming/latest/)

Once the BIG-IP™ Virtual Edition instance is onboarded through Schematics and the F5 Declarative Onboarding Extension, the extension endpoints can be utilized to orchestrate L4-L7 services and logging, creating a fully functional and declarative ADC. Multiple VNFs can be provisioned using the BIG-IP™ Virtual Edition with declared services.

## IBM Cloud IaaS Support

You're provided free technical support through the IBM Cloud™ community and Stack Overflow, which you can access from the Support Center. The level of support that you select determines the severity that you can assign to support cases and your level of access to the tools available in the Support Center. Choose a Basic, Advanced, or Premium support plan to customize your IBM Cloud™ support experience for your business needs.

Learn more: https://www.ibm.com/cloud/support

## Prerequisites

- Have access to [Gen 2 VPC](https://cloud.ibm.com/vpc-ext/).
- The given VPC must have at least one subnet with one IP address unassigned (up to 5 are supported)
- The BIG-IP™ image name can reference the name of a custom image in your region or the public TMOS images available on IBM cloud.

Public BIG-IP™ images available on IBM Cloud are:

**User variable:** ```tmos_image_name```

**Values:**

- ```bigip-14-1-2-6-0-0-2-all-1slot```
- ```bigip-14-1-2-6-0-0-2-ltm-1slot```
- ```bigip-15-1-0-4-0-0-6-all-1slot```
- ```bigip-15-1-0-4-0-0-6-ltm-1slot```

If your regional custom image has the same name as the public image, your custom image will be used.

By default the BIG-IP™ Virtual Edition instance will be unlicensed. The user can choose to include the following license types and their required template attributes

**User variable:** ```license_type```

**Values:**

| ```license_type``` value | Description | Other require variables |
| --------------------- | ----- | ---------- |
| ```none```   | No license activation | None |
| ```byol```   | Bring your own license | ```byol_license_basekey``` |
| ```regkeypool``` | BIG-IQ™ RegKey Pool | ```license_host```, ```license_username```, ```license_password```, ```license_pool``` |
| ```utilitypool``` | BIG-IQ™ Utility Pool (ELA Licensing) | ```license_host```, ```license_username```, ```license_password```, ```license_pool```, ```license_sku_keyword_1```, ```license_sku_keyword_1```, ```license_unit_of_measure``` (optional) |

For pool based license activation, please consult the [BIG-IQ™ Licensing documentation](https://techdocs.f5.com/en-us/bigiq-7-0-0/managing-big-ip-ve-subscriptions-from-big-iq/deploy-license-iq-license-manager.html)

For information on creating custom images for IBM cloud see [TMOS Cloudinit](https://github.com/f5devcentral/tmos-cloudinit)

## Device authentication

The user should create an SSH key in the IBM cloud region. The SSH key name should be included as a user variable.

**User Variable:** ```ssh_key_name```

Once the image completes onboarding, SSH access to the ```root``` user is available on the defined management Floating IP.

The user should also provide an ```admin``` user password.

**User Variable:** ```tmos_admin_password```

If no ```tmos_admin_password``` is provided, a randomized lengthy password will be set. The user can then access the device via SSH authorized key and set the ```admin``` password by using ```passwd admin```.

## Device Network Connectivity

Currently, IBM terraform resources do not provide the ability to obtain VPC subnets by their name. The user will have to know the subnet UUID as input variables.

At least one VPC subnet must be defined:

**User Variable:** ```management_subnet_id```

If only the ```management_subnet_id``` id is defined, the BIG-IP™ will be created as a 1NIC instance. The management UI and APIs can then be reached on port 8443 instead of the standard 443.

Up to five network interfaces can be added to a IBM VPC instnace. If you define additional subnet IDs, these will be mapped to BIG-IP™ data interfaces starting with interface ```1.1```

**User Variables:**

```data_1_1_subnet_id```
```data_1_2_subnet_id```
```data_1_3_subnet_id```
```data_1_4_subnet_id```

## CI Integration via Webhooks

When onboarding is complete, including optional licensing and network interface provisioning, the BIG-IP™ can issue an HTTP(s) POST request to an URL specified by the user.

*User Variables:*

```phone_home_url```

The POST body will be JSON encoded and supply basic instance information:

```json
{
    "status": "SUCCESS",
    "product": "BIG-IP",
    "version": "14.1.2.6-0.0.2.0",
    "hostname": "f5-test-ve-01.local",
    "id": "27096838-e85f-11ea-ac1c-feff0b2c5217",
    "management": "10.243.0.7/24",
    "installed_extensions": ["f5-service-discovery", "f5-declarative-onboarding", "f5-appsvcs", "f5-telemetry", "f5-appsvcs-templates"],
    "do_enabled": true,
    "as3_enabled": false,
    "ts_enabled": false,
    "metadata": {
        "template_source": "/f5devcentral/ibmcloud_schematics_bigip_multinic/tree/master",
        "template_version": 20200825,
        "zone": "eu-de-1",
        "vpc": "r010-e27c516a-22ff-41f5-96b8-e8ea833fd39f",
        "app_id": "undefined"
    }
}
```

The user can optionally define an ```app_id``` variable to tie this instnace for reference.

*User Variables:*

```app_id```

Once onboarding is complete, the user can than access the TMOS™ Web UI, use iControl™ REST API endpoints, or utilize the [F5 BIG-IP™ Extensibility Extensions](https://clouddocs.f5.com/) installed.

## Costs

When you apply the template, the infrastructure resources that you create incur charges as follows. To clean up the resources, you can [delete your Schematics workspace or your instance](https://cloud.ibm.com/docs/schematics?topic=schematics-manage-lifecycle#destroy-resources). Removing the workspace or the instance cannot be undone. Make sure that you back up any data that you must keep before you start the deletion process.

*_VPC_: VPC charges are incurred for the infrastructure resources within the VPC, as well as network traffic for internet data transfer. For more information, see [Pricing for VPC](https://cloud.ibm.com/docs/vpc-on-classic?topic=vpc-on-classic-pricing-for-vpc).

## Dependencies

Before you can apply the template in IBM Cloud, complete the following steps.

1.  Ensure that you have the following permissions in IBM Cloud Identity and Access Management:
    * `Manager` service access role for IBM Cloud Schematics
    * `Operator` platform role for VPC Infrastructure
2.  Ensure the following resources exist in your VPC Gen 2 environment
    - VPC
    - SSH Key
    - VPC with multiple subnets

## Configuring your deployment values

Create a schematics workspace and provide the github repository url (https://github.com/f5devcentral/ibmcloud_schematics_bigip_multinic/tree/master) under settings to pull the latest code, so that you can set up your deployment variables from the `Create` page. Once the template is applied, IBM Cloud Schematics provisions the resources based on the values that were specified for the deployment variables.

### Required values
Fill in the following values, based on the steps that you completed before you began.

| Key | Definition | Value Example |
| --- | ---------- | ------------- |
| `region` | The VPC region that you want your BIG-IP™ to be provisioned. | us-south |
| `instance_name` | The name of the VNF instance to be provisioned. | f5-ve-01 |
| `tmos_image_name` | The name of the VNF image  | bigip-14-1-2-6-0-0-2-all-1slot |
| `instance_profile` | The profile of compute CPU and memory resources to be used when provisioning the BIG-IP™ instance. To list available profiles, run `ibmcloud is instance-profiles`. | cx2-4x8 |
| `ssh_key_name` | The name of your public SSH key to be used. Follow [Public SSH Key Doc](https://cloud.ibm.com/docs/vpc-on-classic-vsi?topic=vpc-on-classic-vsi-ssh-keys) for creating and managing ssh key. | linux-ssh-key |
| `management_subnet_id` | The ID of the management subnet where the instance will be deployed. Click on the subnet details in the VPC Subnet Listing to determine this value | 0717-xxxxxx-xxxx-xxxxx-8fae-xxxxx |

### Optional values
Fill in the following values, based on the steps that you completed before you began.

| Key | Definition | Value Example |
| --- | ---------- | ------------- |
| `tmos_admin_password` | The password to set for the BIG-IP™ admin user. | valid TMOS password |
| `license_type` | What type of license activation to follow. Can be `none`,`byol`,`regkeypool`,`utilitypool` | byol |
| `byol_license_basekey` | The emailed license basekey from F5 for this BIG-IP™ instance. | XXXXX-XXXXX-XXXXX-XXXXX-XXXXXXX |
| `license_host` | The name or IP address of the BIG-IQ™ hosting the pool license. | bigiqlicensor.mydomain.com |
| `license_username` | The name of the BIG-IQ™ user to use for license activation. | admin |
| `license_password` | The password of the BIG-IQ™ user to use for license activation. | admin |
| `license_pool` | The name of the BIG-IQ™ license pool. | BIGIPREGKEYS |
| `license_sku_keyword_1` | The base SKU from BIG-IQ™ utility pool. | XXXXX-XXXXX-XXXXX-XXXXX-XXXXXXX |
| `license_sku_keyword_2` | The product SKU from BIG-IQ™ utility pool. | XXXXX-XXXXX-XXXXX-XXXXX-XXXXXXX |
| `license_unit_of_measure` | The measurement for BIG-IQ™ utility pool. | hourly |
| `data_1_1_subnet_id` | The ID of the first data subnet where the instance will be deployed. Click on the subnet details in the VPC Subnet Listing to determine this value | 0717-xxxxxx-xxxx-xxxxx-8fae-xxxxx |
| `data_1_2_subnet_id` | The ID of the first data subnet where the instance will be deployed. Click on the subnet details in the VPC Subnet Listing to determine this value | 0717-xxxxxx-xxxx-xxxxx-8fae-xxxxx |
| `data_1_3_subnet_id` | The ID of the first data subnet where the instance will be deployed. Click on the subnet details in the VPC Subnet Listing to determine this value | 0717-xxxxxx-xxxx-xxxxx-8fae-xxxxx |
| `data_1_4_subnet_id` | The ID of the first data subnet where the instance will be deployed. Click on the subnet details in the VPC Subnet Listing to determine this value | 0717-xxxxxx-xxxx-xxxxx-8fae-xxxxx |
| `phone_home_url` | The URL for post onboarding web hook  | https://webhook.site/#!/8c71ed42-da62-48ea-a2a5-265caf420a3b |
| `app_id` | Application ID used for CI integration | a044b708-66c4-4f50-a5c8-2b54eff5f9b5 |

## Notes

If there is any failure during VPC instance creation, the created resources must be destroyed before attempting to instantiate again. To destroy resources go to `Schematics -> Workspaces -> [Your Workspace] -> Actions -> Delete` to delete all associated resources.

## Post F5 BIG-IP™ Virtual Edition Onboarding

1. From the VPC list, confirm the F5 BIG-IP™ Virtual Edition is powered ON with green button
2. From the CLI, run `ssh root@<Floating IP>`.
3. Enter 'yes' for continue connecting using ssh your key. This is the ssh key value, you specified in ssh_key variable.
4. Use the ```tmsh``` shell.

Alternatively, the F5 Declarative Onboading, F5 Application Service 3, and F5 Telemetry Streaming service endpoints are available at:

```text
https://<Floating IP>/mgmt/shared/declarative-onboarding
https://<Floating IP>/mgmt/shared/appsvcs
https://<Floating IP>/mgmt/shared/telemetry
```

These endpoints provide declarative orchestration of multiple NFV functions including L4-L7 ADC funcationality, network firewalls, web application firewalls, and DNS services.

## Troubleshooting Known Error States

The following errors were discovered in exhaustive testing of this Schematics template.

### User providing invalid image name

F5 BIG-IP™ Virtual Edition images names can be specified to match either custom images within an account's VPCs or can use the images available as part of the IBM public cloud image catalog. The image ids for the public cloud images are enumerated in a map embedded within the template itself. If the image name provided can not be mapped to a VPC custom image name nor a public cloud image name embedded in the template, the following error will occuring in your plan or apply phase:

```text
XXXX/XX/XX XX:XX:XX Terraform plan | Error: Invalid index
XXXX/XX/XX XX:XX:XX Terraform plan |
XXXX/XX/XX XX:XX:XX Terraform plan |   on compute.tf line 69, in locals:
XXXX/XX/XX XX:XX:XX Terraform plan |   69:   image_id = data.ibm_is_image.tmos_custom_image.id == null ? lookup(local.public_image_map[var.tmos_image_name], var.region) : data.ibm_is_image.tmos_custom_image.id
XXXX/XX/XX XX:XX:XX Terraform plan |     |----------------
XXXX/XX/XX XX:XX:XX Terraform plan |     | local.public_image_map is object with 4 attributes
XXXX/XX/XX XX:XX:XX Terraform plan |     | var.tmos_image_name is "bigip-16-0-0-0-0-12-all-1slot-us-south"
XXXX/XX/XX XX:XX:XX Terraform plan |
XXXX/XX/XX XX:XX:XX Terraform plan | The given key does not identify an element in this collection value.
XXXX/XX/XX XX:XX:XX Terraform plan |
XXXX/XX/XX XX:XX:XX Terraform PLAN error: Terraform PLAN errorexit status 1
XXXX/XX/XX XX:XX:XX Could not execute action
```

To remedy this error, provide a valid image name and re-plan or re-apply.

### Failures within the Schematics service

If the Schematics system can not appropriately construct the execution environment for terraform, a continous repeat of the following log entries can be found at the end of the log of any of the workspace phase logs:

```text
XXXX/XX/XX XX:XX:XX  --- Ready to execute the command ---
XXXX/XX/XX XX:XX:XX  --- Ready to execute the command ---
XXXX/XX/XX XX:XX:XX  --- Ready to execute the command ---
XXXX/XX/XX XX:XX:XX  --- Ready to execute the command ---
XXXX/XX/XX XX:XX:XX  --- Ready to execute the command ---
XXXX/XX/XX XX:XX:XX  --- Ready to execute the command ---
XXXX/XX/XX XX:XX:XX  --- Ready to execute the command ---
XXXX/XX/XX XX:XX:XX  --- Ready to execute the command ---
XXXX/XX/XX XX:XX:XX  --- Ready to execute the command ---
```

If you experience this, please open a support case with IBM cloud so they can examine the Schematics error.

### Failure in the IBM Terraform Providers running in the Schematics service

This template uses only community and IBM authored Terraform resource providers. Both of which are supported under Schematics.

*There are no F5 Terraform resource providers used by this template, thus nothing to report to F5 when Terraform resources fail. All Terraform resources used in this template are supported by IBM.*

When Schematics experiences an error with the community or IBM authorized Terraform resource providers, the cause of the issue will be in the log entries of the failing workspace phase logs. As an example, the following log entry will be present when the `ibm_is_instance` provider experiences issues with the IBM VPC Gen2 instance APIs:

```text
XXXX/XX/XX XX:XX:XX Terraform apply | ibm_is_instance.f5_ve_instance: Creating...
XXXX/XX/XX XX:XX:XX Terraform apply |
XXXX/XX/XX XX:XX:XX Terraform apply | Error: internal server error
XXXX/XX/XX XX:XX:XX Terraform apply |
XXXX/XX/XX XX:XX:XX Terraform apply |   on compute.tf line 109, in resource "ibm_is_instance" "f5_ve_instance":
XXXX/XX/XX XX:XX:XX Terraform apply |  109: resource "ibm_is_instance"
```

If you experience this, please open a support case with IBM cloud so they can examine the Schematic supported Terraform resource providers.

### Failure in the F5 Declarative Onboarding declaration

If your F5 BIG-IP™ Virtual Edition instance fails to reach the operational state, please login to the instance using the supplied IBM VPC Gen2 SSH key at:

`ssh root@<Floating IP>`

The reason for the failures can be found in the `/var/log/restnoded/restnoded.log` file. Search for the term '`Rolling back configuration`' and the cause for the declaration failure should immediately proceed the presence of the searched entry for '`Rolling back configuration`'.

As an example, if the virtualization infrastructure performance is insufficent to appropriately run needed services within F5 TMOS™ you will see log entries like this:

```text
[f5-declarative-onboarding: restWorker.js] tryUntil: got error {"code":503,"message":"tryUntil: max tries reached: Unable to process request /tm/sys/available. Service is unavailable.","name":"Error"}
```

immediately proceeding the line which reads:

```text
[f5-declarative-onboarding: restWorker.js] Rolling back configuration
```

If you see that the system services did not become available, delete the workspace and start another. This type of error happens less then 1% of the time in IBM VPC Gen2 cloud, but has been noted. Creating another workspace from this template is the solution.

As a second example, if there were issues licensing your F5 BIG-IP™ Virtual Edition instance because of Utility pool grant exhaustion or communications error with the BIG-IQ you would see messages like this:

```text
[f5-declarative-onboarding: restWorker.js] Error onboarding: Error waiting for license assignment
```

immediately proceeding the line which reads:

```text
[f5-declarative-onboarding: restWorker.js] Rolling back configuration
```

In this case too, keeping with the spirit of infrastructure as code, the solution would be to correct any issue with the license pool or networking, delete the workspace, and create another from this template.
