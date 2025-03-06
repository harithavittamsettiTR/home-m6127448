#!/usr/bin/python

###################################################################################
##
#   Script Name: storage_scp.py
#   Description:This script performs an audit of storage shares on designated servers. 
#   It systematically collects information about each storage share event details.The collected data is then saved into a specified file for further analysis and record-keeping.
#
#   Author - Haritha Vittamsetti
##################################################################################


import subprocess
import requests
import logging
from datetime import datetime

current_date = datetime.now().strftime("%m%d%Y")
log_directory = '/infra_unixsvcs/unix-support/log'
log_filename = f'{log_directory}/audit_log_{current_date}.log'
logging.basicConfig(filename=log_filename, level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger()

audit_directory = '/infra_unixsvcs/unix-support/bin/storage_audit/'
file_name = f'{audit_directory}/audit_{current_date}'
#audit_file_path = audit_directory + file_name

url = "http://gotmon.int.thomsonreuters.com/api/config_admin_group/unix-support-tr"
 
payload = {}
headers = {}
 
response = requests.request("GET", url, headers=headers, data=payload)
 
response = response.json()
total_servers = response['config_admin_group']['unix-support-tr']
total_servers_str = ' '.join(total_servers)

def run_command():
    
        cmd_1 = f"echo '{total_servers_str}' | /usr/bin/python2 /infra_tools/bin/dbash -u root -c 'uptime' --fail -o /infra_unixsvcs/unix-support/bin/storage_audit/hosts"
        first_task = subprocess.Popen(cmd_1, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True, shell=True)
        stdout, stderr = first_task.communicate()

        if first_task.returncode == 0:
            logger.info(stdout)
            logger.info(f"Return code: {first_task.returncode}")

            cmd_2 = 'cat /infra_unixsvcs/unix-support/bin/storage_audit/hosts.successhostlist | /usr/bin/python2 /infra_tools/bin/dbash -u root -f /infra_unixsvcs/unix-support/bin/storageaudit_master.sh | awk "{print $NF}"'
            second_task = subprocess.Popen(cmd_2, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True, shell=True)
        
            stdout, stderr = second_task.communicate()

            with open(file_name, 'w') as file:
                file.write(stdout)

        else:
            logger.error('Some error while executing the audit script')

def transfer_file(source, destination):
    result = subprocess.run(["scp", source, destination], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    return result

def send_email(subject, body, sender_email, recipient, cc_emails=None):
    body_with_signature = f"{body}\n\nRegards,\nUnix-Support-TR"
    cc_option = f"-c {cc_emails}" if cc_emails else ""
    mailx_command = f"echo '{body_with_signature}' | mailx -s '{subject}' -r {sender_email} {cc_option} {recipient}"
    email_result = subprocess.run(mailx_command, shell=True)
    return email_result

def main():
    run_command()
    #source = f"/tools/infra/temp60days/TR/UNIX_HOSTS/{file_name}"
    destination = "root@c860juu:/data/output/reports/UNIX_AUDITS/"
    if file_name:
        transfer_result = transfer_file(file_name, destination)

        if transfer_result.returncode == 0:
            logger.info("File transferred successfully.")
            logger.info("Sent mail successfully")
            subject = "Storage Audit Report"
            body = "Hi Team,\nStorage audit report is available on the server c860juu in path /data/output/reports/UNIX_AUDITS.\n\nPlease check."
            recipient = "STORAGE-SUPPORT-TR@thomsonreuters.com,kelsey.halverson@thomsonreuters.com"
            #recipient = "haritha.vittamsetti@thomsonreuters.com"
            cc_emails = "UNIX-SUPPORT-TR@thomsonreuters.com"
            #cc_emails = "haritha.vittamsetti@thomsonreuters.com"
            send_email(subject, body, "UNIX-SUPPORT-TR@thomsonreuters.com", recipient, cc_emails)
            
        else:
            logger.error(f"File Transfer failed with return code {transfer_result.returncode}.")
            logger.error(f"Error: {transfer_result.stderr.decode()}")
            subject = "File Transfer Failed"
            body = "File Transfer Failed, please investigate"
            send_email(subject, body, "UNIX-SUPPORT-TR.com", "UNIX-SUPPORT-TR@thomsonreuters.com")
    else:
        logger.error("Audit script failed, file not generated.")


if __name__ == "__main__":
    main()
