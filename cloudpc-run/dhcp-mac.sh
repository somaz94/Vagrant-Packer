#!/bin/sh
virsh net-update service add ip-dhcp-host "<host mac='52:54:00:3f:2a:a1' ip='192.168.121.11' />" --live --config
virsh net-update service add ip-dhcp-host "<host mac='52:54:00:3f:2a:a2' ip='192.168.121.12' />" --live --config
virsh net-update service add ip-dhcp-host "<host mac='52:54:00:3f:2a:a3' ip='192.168.121.13' />" --live --config
virsh net-update service add ip-dhcp-host "<host mac='52:54:00:3f:2a:b1' ip='192.168.121.101' />" --live --config
virsh net-update service add ip-dhcp-host "<host mac='52:54:00:3f:2a:b2' ip='192.168.121.102' />" --live --config
virsh net-update service add ip-dhcp-host "<host mac='52:54:00:3f:2a:c1' ip='192.168.121.201' />" --live --config
