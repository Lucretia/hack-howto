#!/bin/sh

for dev in "$@"; do
	echo $dev > /sys/bus/pci/devices/$dev/driver/unbind
	echo $dev > /sys/bus/pci/drivers/amdgpu/bind
done

echo 1 > /sys/bus/pci/rescan

