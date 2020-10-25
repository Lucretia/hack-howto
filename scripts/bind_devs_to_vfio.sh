#!/bin/sh

DEVS="0000:02:00.0 0000:03:00.0 0000:03:00.1"
#DEVS="0000:02:00.0 0000:01:00.0 0000:01:00.1"

case $1 in
	"-s" | "--set")
		for d in ${DEVS}; do
		        /home/laguest/opt/virt/rebind_dev_to_vfio.sh  ${d}
		done
		;;
	"-h" | "--help")
		echo "Usage: bind_devs_to_vfio.sh [-s|--set] [-h|--help]"
		exit 0
		;;
esac

for d in ${DEVS}; do
	lspci -nnk -s ${d}
done
