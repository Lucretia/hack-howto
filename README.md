README.md
# KVM Hackntosh set up

This is my guide on how to set up a Hackintosh on Virt-Manager.

I've used Kholia's repository which utilised the newer OpenCore firmware method over the old Clover method.

## Hardware

My machine is quite old, but it still works.

* FX-8350 CPU.
* Radeon RX580 GPU.
* Fresco FL1100 based USB PCI-e card.
* RTL8153 USB Ethernet attached to USB card.

## Download the required software

```
$ git clone https@github.com:Lucretia/hack-howto.git
$ cd hack-howto
$ git clone https://github.com/corpnewt/GenSMBIOS
$ git clone https://github.com/corpnewt/ProperTree
$ git clone https://github.com/kholia/OSX-KVM
$ cd OSX-KVM
$ ./fetch-macOS.py
./fetch-macOS.py # Removed the fecting stuff from this log
 #    ProductID    Version   Post Date  Title
 1    061-26578    10.14.5  2019-10-14  macOS Mojave
 2    061-26589    10.14.6  2019-10-14  macOS Mojave
 3    041-91758    10.13.6  2019-10-19  macOS High Sierra
 4    041-88800    10.14.4  2019-10-23  macOS Mojave
 5    041-90855    10.13.5  2019-10-23  Install macOS High Sierra Beta
 6    061-86291    10.15.3  2020-03-23  macOS Catalina
 7    001-04366    10.15.4  2020-05-04  macOS Catalina
 8    001-15219    10.15.5  2020-06-15  macOS Catalina
 9    001-36735    10.15.6  2020-08-06  macOS Catalina
10    001-36801    10.15.6  2020-08-12  macOS Catalina
11    001-51042    10.15.7  2020-09-24  macOS Catalina

Choose a product to download (1-11): 11
qemu-img convert OpenCore-Catalina/OpenCore.qcow -O raw ../../OpenCore-Catalina/OpenCore.raw
```

### ProperTree

**N.B** Beware that ProperTree does not have a scalable UI and is tiny on HiDPI screens.

If ProperTree complains about ```BACKGROUND``` do the following:

```
$ xrdb -load /dev/null
```

## Create the virtual machine in Virt-Manager

Import the Virt-Manager XML template as per the Kholia instructions.

## CPU's

Set up the CPU's with how many cores/threads you want, mine is currently set up:

![CPU's Panel](screenshots/virtmanager/cpus.png)

```
  <vcpu placement="static">4</vcpu>
  <cpu mode="host-model" check="none">
    <topology sockets="1" dies="1" cores="4" threads="1"/>
  </cpu>
```

With a higher spec machine, i.e. Ryzen Threadripper, you could increase this to match what a real Mac would have.

## Memory

I have set up my memory requirements to 8192 MiB (8GB), if you have more, add it.

## Storage

Add the ```BaseSystem.img``` as a **USB** drive, not a hard drive, otherwise you cannot boot the VM into the installer. Kholia does not mention this anywhere.


```
<disk type="file" device="disk">
  <driver name="qemu" type="raw" cache="writeback" io="threads"/>
  <source file="<path-to>/hack-howto/OpenCore-Catalina/OpenCore.raw"/>
  <target dev="sda" bus="usb"/>
  <boot order="1"/>
  <address type="usb" bus="0" port="2"/>
</disk>
<disk type="file" device="disk">
  <driver name="qemu" type="raw"/>
  <source file="<path-to>/hack-howto/macos-vm/OSX-KVM/BaseSystem.img"/>
  <target dev="sdc" bus="usb"/>
  <boot order="2"/>
  <address type="usb" bus="0" port="4"/>
</disk>
<disk type="file" device="disk">
  <driver name="qemu" type="raw" cache="none" io="threads" discard="unmap" detect_zeroes="unmap"/>
  <source file="<path-to>/catalina.raw"/>
  <target dev="sdb" bus="sata"/>
  <boot order="4"/>
  <address type="drive" controller="0" bus="0" target="0" unit="1"/>
</disk>
```

You can repack ```OpenCore.raw``` to qcow2 if you want to save space.

You really want the base OS SATA drive stored on an SSD drive. I have an SSD drive mount inside ```/var/lib/libvirt/images``` which is where I store all my OS images.

I've added an extra data drive which I can mount inside Linux if I need to, this can be VFAT or HFS+, Linux does not have an APFS driver yet.

## Add the physical hardware

I have 3 PCI devices I want to pass through, you need to make sure your devices are set up into separate IOMMU goups.

```
<!-- Add your GPU like this, this specific to my VM, you may need to modify the bus numbers in the address tag, don't modify any other parameters in that tag -->
<hostdev mode="subsystem" type="pci" managed="yes">
  <driver name="vfio"/>
  <source>
    <address domain="0x0000" bus="0x03" slot="0x00" function="0x0"/>
  </source>
  <!-- GPU's have 2 functions, video and audio -->
  <address type="pci" domain="0x0000" bus="0x01" slot="0x00" function="0x0" multifunction="on"/>
</hostdev>

<!-- GPU Audio device -->
<hostdev mode="subsystem" type="pci" managed="yes">
  <driver name="vfio"/>
  <source>
    <address domain="0x0000" bus="0x03" slot="0x00" function="0x1"/>
  </source>
  <address type="pci" domain="0x0000" bus="0x01" slot="0x00" function="0x1"/>
</hostdev>

<!-- My USB PCI-e card -->
<hostdev mode="subsystem" type="pci" managed="yes">
  <driver name="vfio"/>
  <source>
    <address domain="0x0000" bus="0x02" slot="0x00" function="0x0"/>
  </source>
  <address type="pci" domain="0x0000" bus="0x03" slot="0x00" function="0x0"/>
</hostdev>
```

## Remove HDA audio

MacOS doesn't seem to like the HDA device that QEMU provides, I've tried all of the hardware provided and none work. Apparently, if you do get it working it's not the best anyway. I ended up just using HDMI audio, but this is no good if you don't have speakers on your monitor.

## Find your Ethernet MAC address

```
$ ip a  # Output trimmed
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether AA:BB:CC:DD:EE:FF brd ff:ff:ff:ff:ff:ff
#              ^^^^^^^^^^^^^^^^^
```

or
```
$ ifconfig  # Output trimmed
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.0.30  netmask 255.255.255.0  broadcast 192.168.0.255
        ether AA:BB:CC:DD:EE:FF  txqueuelen 1000  (Ethernet)
#             ^^^^^^^^^^^^^^^^^
```

## Modify the config.plist

```
$ mkdir -p mnt/opencore
$ sudo mount OSX-KVM/OpenCore-Catalina/OpenCore.raw -o loop,offset=$((010*2048)) mnt/opencore
```

Generate your SMBIOS, select option 3 and give either ```iMacPro1,1``` or ```MacPro7,1``` as the SMBIOS when asked:

```
$ python GenSMBIOS/GenSMBIOS.command
```

Make a note of it as the tool clears the screen. Place the data into your config list:

```
        </dict>
        <key>PlatformInfo</key>
        <dict>
                <key>Automatic</key>
                <true/>
                <key>Generic</key>
                <dict>
                        <key>AdviseWindows</key>
                        <false/>
                        <key>MLB</key>
                        <string>**Board Serial**</string>
                        <key>ROM</key>
                        <data>**Ethernet MAC without colons, e.g. AABBCCDDEEFF**</data>
                        <key>SpoofVendor</key>
                        <true/>
                        <key>SystemProductName</key>
                        <string>SMBIOS</string>
                        <key>SystemSerialNumber</key>
                        <string>**Serial**</string>
                        <key>SystemUUID</key>
                        <string>**SmUUID**</string>
                </dict>
```

## Issues

On booting the machine the OS will set you up with an accelerated framebuffer, it's the default one ```AMDFrameBuffer``` which is generated on the fly. I cannot get HDMI 2.0 to work to get HiDPI screen resolutions and the Display settings doesn't show the HiDPI settings, only the scalable ones.

![HiDPI Settings](https://www.eizoglobal.com/support/compatibility/dpi_scaling_settings_mac_os_x/image01.jpg)

![Normal Settings](screenshots/catalina/settings-displays.png)

