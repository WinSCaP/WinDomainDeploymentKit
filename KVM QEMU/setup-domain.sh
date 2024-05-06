#!/bin/bash

# Create automatic installation iso
rm unattend.iso
mkdir unattend
cp autounattend.xml unattend
mkisofs -o unattend.iso -J -r unattend
rm -rf ./unattend   

# Function to create a virtual machine
create_vm() {
    local vm_name=$1
    local disk1="${HOME}/VMs/${vm_name}_disk1.qcow2"
    local disk2="${HOME}/VMs/${vm_name}_disk2.qcow2"

    virt-install \
    --name "$vm_name" \
    --ram 2048 \
    --vcpus 2 \
    --disk path="$disk1",size=60,format=qcow2,bus=virtio,sparse=true \
    --disk path="$disk2",size=50,format=qcow2,bus=virtio,sparse=true \
    --os-variant win2k22 \
    --network network=internal_bridge,model=virtio \
    --graphics vnc \
    --cdrom ../iso/windows-server-2022.iso \
    --disk path=../iso/virtio-win-0.1.248.iso,device=cdrom \
    --disk path=unattend.iso,device=cdrom \
    --boot once,cdrom,hd
}

create_vm "DC01"
create_vm "DC02"
create_vm "CA01"
create_vm "DFS01"
create_vm "DB01"
create_vm "SCCM01"
create_vm "SCCM02"
