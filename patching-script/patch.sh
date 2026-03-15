#!/bin/bash

DATE=$(date +%Y%m%d)
HOST=$(hostname)
BASE_DIR="/home/student/patching_$DATE"
LOG_FILE="$BASE_DIR/patching.log"
PRECHECK="$BASE_DIR/pre-checks"
POSTCHECK="$BASE_DIR/post-checks"
OLD_KERNEL=$(uname -r)


#-------------Root Check--------------

if [[ $EUID -ne 0 ]]; then
	echo " Run the script as root"
	exit 1
fi

mkdir -p "$BASE_DIR"
echo " Patching started on $HOST at $(date)" | tee -a "$LOG_FILE"

echo "Running kernel before patch: $OLD_KERNEL" >> "$LOG_FILE"


#################################
#Pre-checks
#################################

{
echo "#################################"
echo "Pre-checks"
echo "#################################"
echo "Date: $(date)"
echo "Hostname: $(hostname)"
echo "Kernel: $(uname -r)"
echo "Uptime: $(uptime)"
echo
echo " File System Info: "
df -PTh
echo
echo "Memory Usage:"
free -m
echo
echo "Installed Kernels:"
rpm -qa --last kernel
echo
} >> "$PRECHECK"

echo "Pre-check completed" | tee -a "$LOG_FILE"

#################################
#REPOSITORY CHECK
#################################

yum repolist &>> "$LOG_FILE"

if [[ $? -ne 0 ]]; then
	echo " Repository check failed. Exiting..."
	exit 1
fi

#################################
#Clean Cache
#################################

echo " Cleaning yum cache..." | tee -a "$LOG_FILE"
yum clean all &>> "$LOG_FILE"
yum makecache &>> "$LOG_FILE"

#################################
#PATCHING
#################################

echo "Patching Started..." | tee -a "$LOG_FILE"

yum update -y | tee -a "$LOG_FILE"


if [[ $? -ne 0 ]]; then
	echo " Patching Failed" | tee -a "$LOG_FILE"
	exit 1
fi

echo "Patching Completed Successfully" | tee -a "$LOG_FILE"


NEW_KERNEL=$(rpm -q kernel | sed 's/kernel-//' | tail -1)

if [[ $OLD_KERNEL != $NEW_KERNEL ]]; then
	echo "Kernel updatd. Rebooting the system..."
	sleep 5
	reboot
else
	echo "No Kernel Update detected. Reboot not required" | tee -a "$LOG_FILE"
fi



