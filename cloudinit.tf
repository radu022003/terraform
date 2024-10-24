resource "proxmox_vm_qemu" "cloudinit-test2" {
    count = 2
    # set the vm id in proxmox
    vmid = 1000 + count.index
    name = "terraform-test-vm-${count.index}"
    desc = "A test for using terraform and cloudinit"

    # Node name has to be the same name as within the cluster
    # this might not include the FQDN
    target_node = "pve"

    # The destination resource pool for the new VM
#    pool = "pool0"

    # The template name to clone this vm from
    clone = "VM 9000"

    # Activate QEMU agent for this VM
    agent = 1

    os_type = "cloud-init"
    cores = 2
    sockets = 1
    vcpus = 0
    cpu = "host"
    memory = 2048
    scsihw = "virtio-scsi-pci"

    # Setup the disk
    disks {
        ide {
            ide2 {
                cloudinit {
                    storage = "local-lvm"
                }
            }
        }
        scsi {
            scsi0 {
                disk {
                    size            = 32
                    cache           = "writeback"
                    storage         = "local-lvm"
                    #storage_type    = "rbd"
                    #iothread        = true
                    #discard         = true
                    replicate       = true
                }
            }
        }
    }
    vga {
        type = "std"
        memory = 4
    }
    # Setup the network interface and assign a vlan tag: 256
    network {
        model = "virtio"
        bridge = "vmbr0"
        #tag = 256
    }

    # Setup the ip address using cloud-init.
    boot = "order=scsi0"
    # Keep in mind to use the CIDR notation for the ip.
    ipconfig0 = "ip=192.168.250.22${count.index +1}/24,gw=192.168.250.1"
    sshkeys = <<EOF
    ${var.ssh_pub_key}
    EOF
    serial {
      id   = 0
      type = "socket"
    }
    
    ciuser = "radu"
    cipassword = "r4duc4nu"

}

resource "null_resource" "example" {
    depends_on = [proxmox_vm_qemu.cloudinit-test2[0], proxmox_vm_qemu.cloudinit-test2[1]]
    provisioner "remote-exec" {
        inline = [
            "sleep 40",
            "ansible-playbook -i /root/terraform/inventory.yml /root/terraform/playbook.yml"
        ]

        connection {
            type        = "ssh"
            user        = "root"
            private_key = file("C:\\Users\\radun\\.ssh\\id_rsa_linux")
            host        = "192.168.250.94"
        }
    }
}

output "vm_ips" {
  value = [for vm in proxmox_vm_qemu.cloudinit-test2 : substr(vm.ipconfig0, 3, 15) ]
}