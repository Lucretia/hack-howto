#!/bin/sh

case $1 in
	"-s" | "--set")
		echo 1 > /sys/module/kvm/parameters/ignore_msrs 
		;;
	"-h" | "--help")
		echo "Usage: ready_kvm_for_mac.sh [-s|--set] [-h|--help]"
		exit 0
		;;
esac

echo "MSRS: " `cat /sys/module/kvm/parameters/ignore_msrs`

