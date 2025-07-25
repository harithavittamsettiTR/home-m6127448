#!/bin/bash

# Specify hostname
#hostname=$(hostname)

# Output file
output_file="/var/tmp/nfs_entries.txt"


# Function to fetch NFS entries from vfstab
fetch_vfstab_nfs() {
    while read -r line; do
	if [[ ! "$line" =~ ^[[:space:]]*# ]]; then
        	if [[ ( "$line" == *nfs* ||  "$line" == *cifs* ) &&   "$line" != *^\s*#* ]]; then
           		# Extract the first two entries
            		first_two_entries=$(echo "$line" | awk '{print $1, $3}')
            		echo " configured-vfstab : $first_two_entries" >> "$output_file"
            		#echo " (/etc/vfstab): $first_two_entries" >> "$output_file"
            		#echo "$hostname : (/etc/vfstab): $first_two_entries" >> "$output_file"
        	fi
	fi
    done < /etc/vfstab
}

# Function to fetch NFS entries from auto_* files
fetch_auto_nfs() {
    for file in /etc/auto_*; do
        if [ -f "$file" ]; then
		#if [[ ! "$file" =~ [0-9] || ! "$file" =~ \. ]]; then
		if [[ ! "$file" =~ [0-9] && ! "$file" =~ \. ]]; then
            		while read -r line; do
                		#if [[ ! "$line" =~ ^# && ( "$line" == *cps* || "$line" == *cis* ) && ! "$line" == *localhost* ]]; then
                		if [[ ! "$line" =~ ^# && ( "$line" == *cps* || "$line" == *cis*  || "$line" == *localhost* ) ]]; then
                    			# Extract the first two entries
                    			first_two_entries=$(echo "$line" | awk '{print  $NF, $1'})
                    			echo " configured-autofs:  $first_two_entries" >> "$output_file"
                    			#echo "($file) :  $first_two_entries" >> "$output_file"
                    			#echo "$hostname : ($file) :  $first_two_entries" >> "$output_file"
                		fi
            		done < "$file"
		fi
        fi
    done
}

#Print the output file
cat $"$output_file"

# Clear the output file if it exists
> "$output_file"


# Execute the functions
fetch_vfstab_nfs
fetch_auto_nfs

