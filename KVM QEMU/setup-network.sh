sudo virsh net-define internal_bridge.xml
sudo virsh net-start internal_bridge
sudo virsh net-autostart internal_bridge

sudo systemctl restart libvirtd
