#!/bin/bash
# @todo execute as non

# Define constants & variables
os_username="pi" #Default username
working_folder="/tmp/raspberry-pi-tools-$(date +%s)"; #Working folder

# Define functions
os_does_not_support_raspberry_version_error () {
  echo "$1 for Raspberry Pi Version $2 is not supported!" && exit 1;
}

echo "Setupscript for Raspberry Pi SD's"
echo
echo "@author Kevin Veen-Birkenbach [kevin@veen.world]"
echo "@since 2017-03-12"
echo
echo "The images will be stored in /home/\$username/images/."
echo "Create temporary working folder in $working_folder";
mkdir
if [ $(id -u) != 0 ];then
    echo "This script must be executed as root!" && exit 1
fi
echo "Please type in the username from which the SSH-Key should be copied:" #@todo remove
read -r username;
image_folder="/home/$username/Images/";
echo "List of actual mounted devices:"
echo
ls -lasi /dev/ | grep -E "sd|mm"
echo
while [ \! -b "$of_device" ]
	do
		echo "Please select the correct SD-Card."
		echo "/dev/:"
		read -r device
		$of_device="/dev/$device"
done
echo "Which Raspberry Pi version do you want to use?"
read -r version
echo "Image for Raspberry Pi $version will be used..."
echo "Which OS do you want to use?"
echo "1) arch"
echo "2) moode"
echo "3) retropie"
echo "Please type in the os:"
read -r os
case "$os" in
  "arch")
    os_username="arch"
    base_download_url="http://os.archlinuxarm.org/os/";
    case "$version" in
      "1")
        imagename="ArchLinuxARM-rpi-latest.tar.gz"
        ;;
      "2" | "3")
        imagename="ArchLinuxARM-rpi-2-latest.tar.gz"
        ;;
      "4")
        imagename="ArchLinuxARM-rpi-4-latest.tar.gz"
        ;;
      *)
        os_does_not_support_raspberry_version_error $os $version
        ;;
    esac
    ;;
  "moode")
    base_download_url="https://github.com/moode-player/moode/releases/download/r651prod/"
    imagename="moode-r651-iso.zip";
    ;;
  "retropie")
    base_download_url="https://github.com/RetroPie/RetroPie-Setup/releases/download/4.6/";
    case "$version" in
      "1")
        imagename="retropie-buster-4.6-rpi1_zero.img.gz"
        ;;

      "2" | "3")
        imagename="retropie-buster-4.6-rpi2_rpi3.img.gz"
        ;;

      "4")
        imagename="retropie-buster-4.6-rpi4.img.gz"
        ;;
      *)
        os_does_not_support_raspberry_version_error $os $version
        ;;
    esac
    ;;
  *)
    echo "The operation system \"$os\" is not supported yet!" && exit 1;
  ;;
esac
download_url="$base_download_url$imagename"
$imagepath="$image_folder$imagename"
if [ \! -f "$imagepath" ]
	then
		echo "The selected image \"$imagename\" doesn't exist under local path \"$imagepath\"."
		if [ \! -f "$imagepath" ]
			then
				echo "Image \"$imagename\" gets downloaded from \"$download_url\""
				wget $download_url
		fi
fi
case "$os" in
  "arch")
    bootpath=$workingpath"boot"
    rootpath=$workingpath"root"
    ssh_key_source="/home/$username/.ssh/id_rsa.pub"
    ssh_key_target="$rootpath/home/$username/.ssh/authorized_keys"

    if [ "${of_device:5:1}" != "s" ]
    	then
    		partion="p"
    	else
    		partion=""
    fi
    ofiboot=$of_device$partion"1"
    ofiroot=$of_device$partion"2"
    echo "fdisk wird ausgefuehrt..."
    (	echo "o"	#Type o. This will clear out any partitions on the drive.
    	echo "p"	#Type p to list partitions. There should be no partitions left
    	echo "n"	#Type n,
    	echo "p"	#then p for primary,
    	echo "1"	#1 for the first partition on the drive,
    	echo ""		#press ENTER to accept the default first sector,
    	echo "+100M"	#then type +100M for the last sector.
    	echo "t"	#Type t,
    	echo "c"	#then c to set the first partition to type W95 FAT32 (LBA).
    	echo "n"	#Type n,
    	echo "p"	#then p for primary,
    	echo "2"	#2 for the second partition on the drive,
    	echo ""		#and then press ENTER twice to accept the default first and last sector.
    	echo ""
    	echo "w"	#Write the partition table and exit by typing w.
    )| fdisk "$of_device"

    #Bootpartion formatieren und mounten
    echo "Generate and mount boot-partition..."
    mkfs.vfat "$ofiboot"
    mkdir "$bootpath"
    mount "$ofiboot" "$bootpath"

    #Rootpartition formatieren und mounten
    echo "Generate and mount root-partition..."
    mkfs.ext4 "$ofiroot"
    mkdir "$rootpath"
    mount "$ofiroot" "$rootpath"

    echo "Die Root-Dateien werden auf die SD-Karte aufgespielt..."
    bsdtar -xpf "$imagepath" -C "$rootpath"
    sync

    echo "Die Boot-Dateien werden auf die SD-Karte aufgespielt..."
    mv -v $rootpath"/boot/"* "$bootpath"

    if [ "$username" != "" ] && [ -f "$ssh_key_source" ]
    	then
    		echo "SSH key will be copied to raspberryPi.."
    		mkdir -v "$rootpath/home/$os_username/.ssh"
    		cat "$ssh_key_source" > "$ssh_key_target"
    		chown -R 1000 "$rootpath/home/$os_username/.ssh"
    		chmod -R 400 "$rootpath/home/$os_username/.ssh"
        #echo "SSH file will be generated..."
        #echo "" > "$bootpath/ssh" # Why does this generation exist? Remove if possible
    fi

    echo "Unmount partitions..."
    umount -v "$rootpath" "$bootpath"

  *)
  echo "The operation system \"$os\" is not supported yet!" && exit 1;
;;
esac
rm -r "$working_folder"