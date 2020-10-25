#!/bin/sh

echo $1 > /sys/bus/pci/devices/$1/driver/unbind
echo $1 > /sys/bus/pci/drivers/vfio-pci/bind
echo 1 > /sys/bus/pci/rescan



