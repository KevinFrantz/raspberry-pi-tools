#!/bin/bash
echo "Setupscript for Raspberry Pi SD's"
echo
echo "@author Kevin Veen-Birkenbach [kevin@veen.world]"
echo "@since 2017-03-12"
echo
echo "The images will be stored in /home/\$username/images/."
tmp_folder="/tmp/raspberry-pi-tools-$(date +%s)";
echo "Create temporary working folder in $tmp_folder";
if [ $(id -u) != 0 ];then
    echo "This script must be executed as root!" && exit 1
fi
echo "Please type in the username from which the SSH-Key should be copied:"
read username;
image_folder="/home/$username/images/";
echo "List of actual mounted devices:"
echo
ls -lasi /dev/ | grep -E "sd|mm"
echo
while [ \! -b "$ofi" ]
	do
		echo "Please select the correct SD-Card."
		echo "/dev/:"
		read device
		ofi="/dev/$device"
done
while [ "$workingpath" == "" ]
	do
		echo "Bitte waehlen Sie den Arbeitspfad zu $(pwd) aus:"
		read workingpath
		if [ "${workingpath:0:1}" != "/" ]
			then
				workingpath=$(pwd)"/"$workingpath
		fi
		if [ -d "$workingpath" ]
			then
				i=$((${#workingpath}-1)) #Letzte Zeichenstelle ermitteln
				if [ "${workingpath:$i:1}" != "/" ]
					then
						workingpath=$workingpath"/"
				fi
			else
				echo "Der ausgewaehlte Arbeitspfad existiert nicht."
				workingpath=""
		fi

done
echo "Which raspberry pi version do you want to use?"
read version
echo "Image for RaspberryPi $version will be used..."
echo "Which OS do you want to use?"
echo "1) arch"
echo "2) moode"
echo "3) retropie"
echo "Please type in the os:"
read os
case "$os" in
  "arch")
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
        echo "ArchLinux for RaspberryPi Version $version is not supported!" && exit 1;
        ;;
    esac
    downloadurl="http://os.archlinuxarm.org/os/$imagename"
    ;;
  "moode")
    imagename="moode-r651-iso.zip";
    downloadurl="https://github.com/moode-player/moode/releases/download/r651prod/moode-r651-iso.zip";
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
        echo "RetroPie for RaspberryPi Version $version is not supported!" && exit 1;
        ;;
    esac
    downloadurl="$base_download_url$imagename"
    ;;
  *)
    echo "The operation system \"$os\" is not supported yet!" && exit 1;
  ;;
  esac
while [ "$imagepath" == "" ]
	do
		echo "Setzen Sie den Imagenamen(Standart:$workingpath$imagename)"
		read image
		if [ "$image" == "" ]
			then
				imagepath=$workingpath$imagename
			else
				imagepath=$workingpath$image
		fi
		if [ \! -f "$imagepath" ]
			then
				echo "Das ausgewaehlte Image existiert nicht!"
				#Image ggf. downloaden
				if [ \! -f "$imagepath" ]
					then
						echo "Image wird gedownloadet..."
						wget $downloadurl
				fi
		fi

done

echo "Die Arbeitsvariablen werden gesetzt..."
bootpath=$workingpath"boot"
rootpath=$workingpath"root"

ssh_key_source="/home/$user/.ssh/id_rsa.pub"
ssh_key_target="$rootpath/home/alarm/.ssh/authorized_keys"

if [ "${ofi:5:1}" != "s" ]
	then
		partion="p"
	else
		partion=""
fi
ofiboot=$ofi$partion"1"
ofiroot=$ofi$partion"2"
echo "Arbeitsverzeichnis: $workingpath"
echo "Rootpath: $rootpath"
echo "Bootpath: $bootpath"
echo "Imagepath: $imagepath"
echo "SD-Karte: $ofi"
echo "SD-Karte-Partition 1(boot): $ofiboot"
echo "SD-Karte-Partition 2(root): $ofiroot"
echo "SSH-Source-Path: $ssh_key_source"
echo "SSH-Target-Path: $ssh_key_target"
echo "Bestaetigen Sie mit der Enter-Taste. Zum Abbruch Ctrl + Alt + C druecken"
read bestaetigung
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
)| fdisk "$ofi"

#Bootpartion formatieren und mounten
echo "Generiere und mounte boot-Partition..."
mkfs.vfat "$ofiboot"
mkdir "$bootpath"
mount "$ofiboot" "$bootpath"

#Rootpartition formatieren und mounten
echo "Generiere und mounte root-Partition..."
mkfs.ext4 "$ofiroot"
mkdir "$rootpath"
mount "$ofiroot" "$rootpath"

echo "Die Root-Dateien werden auf die SD-Karte aufgespielt..."
bsdtar -xpf "$imagepath" -C "$rootpath"
sync

echo "Die Boot-Dateien werden auf die SD-Karte aufgespielt..."
mv -v $rootpath"/boot/"* "$bootpath"

if [ "$user" != "" ] && [ -f "$ssh_key_source" ]
	then
		echo "Der SSH-Key wird auf den Raspberry kopiert..."
		mkdir -v "$rootpath/home/alarm/.ssh"
		cat "$ssh_key_source" > "$ssh_key_target"
		chown -R 1000 "$rootpath/home/alarm/.ssh"
		chmod -R 400 "$rootpath/home/alarm/.ssh"
    echo "SSH File wird angelegt..."
    echo "" > "$bootpath/ssh"
fi

echo "Script rauemt das Verzeichnis auf..."
umount "$rootpath" "$bootpath"
rm -r "$rootpath"
rm -r "$bootpath"
