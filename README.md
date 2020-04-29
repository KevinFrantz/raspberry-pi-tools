# Raspberry Pi sdc tools
This repository contains some shell scripts to install Arch Linux for the Raspberry Pi on a SD-Card and to backup a SD-Card.

## Setup
### Guided
To install a Linux distribution manually on a SD card type in:

```bash
  bash ./sd_setup.sh
```
### Piped
To pase the configuration to the program use this syntax:
```bash
(
  echo "$USER"    #The username
  echo "mmcblk1"  #The device
  echo "3"        #The raspberry pi number
  echo "arch"     #The operation system
)| sudo bash ./sd_setup.sh
```
## Backup
To backup a SD card type in:

```bash
  bash ./sd_backup.sh
```

## License

<a rel="license" href="http://creativecommons.org/licenses/by-nc/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-nc/4.0/88x31.png" /></a><br />This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-nc/4.0/">Creative Commons Attribution-NonCommercial 4.0 International License</a>.
