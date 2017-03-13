#!/bin/bash
echo "Setupscript fuer Raspberry Pi SD's"
echo "Dieses Script  muss aus dem Ordner aufgerufen werden, in welchem ArchLinuxARM-rpi-2-latest.tar.gz liegt"
echo 
echo "@author KevinFrantz"
echo "@since 2017-03-12"
echo 
echo "Liste der aktuell gemounteten Geraete:"
echo 
ls -lasi /dev/ | grep "sd"
echo "(Die Liste zeigt nur Geraete an welche auf den Filter /dev/sd* passen)"
echo
while [ \! -b "$ifi" ]
	do
		echo "Bitte waehlen Sie die korrekte SD-Karte aus:"
		echo "/dev/:"
		read device
		ifi="/dev/$device" 
done 
#Pruefen ob der Pfad existiert hinzufuegen
while [ "$workingpath" == "" ]
	do
		echo "Bitte waehlen Sie den Arbeitspfad zu $(pwd) aus:"
		read workingpath
		if [ "${workingpath:0:1}" != "/" ]
			then
				workingpath=$(pwd)"/"$workingpath
		fi
		if [-d "$workingpath" ]
			then
				i=$((${#workingpath}-1))
				if [ "${workingpath:$i:1}" != "/"]
					then 
						workingpath=$workingpath"/"				
				fi 	
			else
				echo "Der ausgewaehlte Arbeitspfad existiert nicht."
				workingpath=""
		fi

done
echo "Die Arbeitsvariablen werden gesetzt..."
imagepath=$workingpath"ArchLinuxARM-rpi-2-latest.tar.gz"
bootpath=$workingpath"boot" 
rootpath=$workingpath"root"
echo "Arbeitsverzeichnis: $workingpath"
echo "Rootpath: $rootpath"
echo "Bootpath: $bootpath"
echo "Imagepath: $imagepath"
echo "SD-Karte: $ifi"
echo "Bestaetigen Sie mit der Enter-Taste. Zum Abbruch Ctrl + Alt + C druecken"
read bestaetigung
echo 
echo "Follow this steps:"
echo "Type o. This will clear out any partitions on the drive."
echo "Type p to list partitions. There should be no partitions left."
echo "Type n, then p for primary, 1 for the first partition on the drive, press ENTER to accept the default first sector, then type +100M for the last sector."
echo "Type t, then c to set the first partition to type W95 FAT32 (LBA)."
echo "Type n, then p for primary, 2 for the second partition on the drive, and then press ENTER twice to accept the default first and last sector."
echo "Write the partition table and exit by typing w."
echo "Bestaetigen Sie mit der Enter-Taste. Zum Abbruch Ctrl + Alt + C druecken"
read bestaetigung
fdisk $ifi
echo "Generiere und mounte boot-Partition..."
mkfs.vfat $ifi"1"
mkdir $bootpath
mount $ifi"1" $bootpath
echo "Generiere und mounte root-Partition..."
mkfs.ext4 $ifi"2"
mkdir $rootpath
mount $ifi"2" $rootpath
if [\! -f "$imagepath" ]
	then
		wget http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-2-latest.tar.gz
fi
bsdtar -xpf $imagepath -C $rootpath
sync
mv $rootpath"/boot/*" $bootpath
echo "Script rauemt das Verzeichnis auf..."
umount $rootpath $bootpath
rm -r $rootpath
rm -r $bootpath
