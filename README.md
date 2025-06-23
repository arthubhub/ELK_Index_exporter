# ELK_Index_exporter
You are looking for a way to **export elk logs in json** ?
-> Use the ELK_Index_exporter

## Requirements
- jq
- curl
- gzip

## Process
- The program checks the required packages
- It creates an output dir
- It reads the indexes as input
- For each index : it reads the whole index into a json temp file, scrolling along the file with GET requests
- After downloading each index it compresses it, and remove the temp file

## Usage

### 1° Configuration

- In the export_all.sh, setup your parameters (dont push your creds ;]) :
  ```bash
  #!/bin/bash

  ELASTICSEARCH_HOST="127.0.0.1:9200" # -> "192.168.1.1:9200"
  USERNAME="elastic" # -> "elastic"
  PASSWORD="mySup3rP4ssw0rd" # -> "yourpass"
  INDEX_LIST_FILE="index_list.txt"
  OUTPUT_DIR="./exports"
  BATCH_SIZE=5000
  SCROLL_TIMEOUT="5m"
  ```
- List your indexes to export (I will not explain how to find them on kibana or with a curl command, do it yourself ^^)
  ```bash
  #Here is an example with indexes created from a datastream :
  .ds-logs-generic-default-2025.06.13-000001
  .ds-logs-netflow-default-2025.06.13-000001
  .ds-logs-router_netflow-default-2025.06.13-000001
  .ds-logs-router_syslog-default-2025.06.13-000001
  .ds-logs-radius-default-2025.06.13-000001
  .ds-filebeat-8.13.0-2025.06.13-000001  
  ```
### 2° Launch your script 
- Try first without indexes if you want to check the connection !
- To run, simply do : `chrmod +x ./export_all.sh`
- Then : `./export_all.sh`
- If you want to save output : `./export_all.sh >> app_logs.txt`

### 3° Example of usage

- Running a test with a list of ~13M logs
- `./export_all.sh >> index_list.txt"`
- `tail -f index_list.txt`
- Result : `cat script_logs.txt | grep -v "Batch : 5000 documents | Total exporté :"`
    ```text
    [2025-06-23 13:44:04] Début de l'export des index Elasticsearch
    [2025-06-23 13:44:04] Vérification des prérequis...
    [SUCCESS] Prérequis vérifiés
    [2025-06-23 13:44:04] Répertoire de sortie créé : ./exports
    [2025-06-23 13:44:04] ----------------------------------------
    [2025-06-23 13:44:04] Début de l'export de l'index : .ds-logs-generic-default-2025.06.13-000001
    [2025-06-23 13:44:04] Nombre total de documents : 11858
    [2025-06-23 13:44:06] Premier batch : 5000 documents exportés
    [2025-06-23 13:44:07] Batch : 1858 documents | Total exporté : 11858/11858
    [2025-06-23 13:44:08] Batch : 0 documents | Total exporté : 11858/11858
    [SUCCESS] Index .ds-logs-generic-default-2025.06.13-000001 exporté : 11858 documents dans ./exports/.ds-logs-generic-default-2025.06.13-000001.json
    [SUCCESS] Fichier compressé : ./exports/.ds-logs-generic-default-2025.06.13-000001.json.gz
    [2025-06-23 13:44:08] ----------------------------------------
    [2025-06-23 13:44:08] Début de l'export de l'index : .ds-logs-netflow-default-2025.06.13-000001
    [2025-06-23 13:44:08] Nombre total de documents : 1502414
    [2025-06-23 13:44:09] Premier batch : 5000 documents exportés
    [2025-06-23 13:52:21] Batch : 2414 documents | Total exporté : 1502414/1502414
    [2025-06-23 13:52:21] Batch : 0 documents | Total exporté : 1502414/1502414
    [SUCCESS] Index .ds-logs-netflow-default-2025.06.13-000001 exporté : 1502414 documents dans ./exports/.ds-logs-netflow-default-2025.06.13-000001.json
    [SUCCESS] Fichier compressé : ./exports/.ds-logs-netflow-default-2025.06.13-000001.json.gz
    [2025-06-23 13:53:19] ----------------------------------------
    [2025-06-23 13:53:19] Début de l'export de l'index : .ds-logs-router_netflow-default-2025.06.13-000001
    [2025-06-23 13:53:19] Nombre total de documents : 5461188
    [2025-06-23 13:53:20] Premier batch : 5000 documents exportés
    [2025-06-23 14:24:59] Batch : 1188 documents | Total exporté : 5461188/5461188
    [2025-06-23 14:24:59] Batch : 0 documents | Total exporté : 5461188/5461188
    [SUCCESS] Index .ds-logs-router_netflow-default-2025.06.13-000001 exporté : 5461188 documents dans ./exports/.ds-logs-router_netflow-default-2025.06.13-000001.json
    [SUCCESS] Fichier compressé : ./exports/.ds-logs-router_netflow-default-2025.06.13-000001.json.gz
    [2025-06-23 14:27:14] ----------------------------------------
    [2025-06-23 14:27:15] Début de l'export de l'index : .ds-logs-router_syslog-default-2025.06.13-000001
    [2025-06-23 14:27:15] Nombre total de documents : 6955737
    [2025-06-23 14:27:16] Premier batch : 5000 documents exportés
    [2025-06-23 15:06:18] Batch : 737 documents | Total exporté : 6955737/6955737
    [2025-06-23 15:06:18] Batch : 0 documents | Total exporté : 6955737/6955737
    [SUCCESS] Index .ds-logs-router_syslog-default-2025.06.13-000001 exporté : 6955737 documents dans ./exports/.ds-logs-router_syslog-default-2025.06.13-000001.json
    [SUCCESS] Fichier compressé : ./exports/.ds-logs-router_syslog-default-2025.06.13-000001.json.gz
    [2025-06-23 15:09:02] ----------------------------------------
    [2025-06-23 15:09:02] Début de l'export de l'index : .ds-logs-radius-default-2025.06.13-000001
    [2025-06-23 15:09:02] Nombre total de documents : 529
    [2025-06-23 15:09:02] Premier batch : 529 documents exportés
    [2025-06-23 15:09:02] Batch : 0 documents | Total exporté : 529/529
    [SUCCESS] Index .ds-logs-radius-default-2025.06.13-000001 exporté : 529 documents dans ./exports/.ds-logs-radius-default-2025.06.13-000001.json
    [SUCCESS] Fichier compressé : ./exports/.ds-logs-radius-default-2025.06.13-000001.json.gz
    [2025-06-23 15:09:02] ----------------------------------------
    [2025-06-23 15:09:02] Début de l'export de l'index : .ds-filebeat-8.13.0-2025.06.13-000001
    [2025-06-23 15:09:02] Nombre total de documents : 20
    null
    [2025-06-23 15:09:02] ========================================
    [2025-06-23 15:09:02] Export terminé !
    [2025-06-23 15:09:02] Total des index : 6
    [SUCCESS] Exports réussis : 5
    [2025-06-23 15:09:02] Fichiers de sortie dans : ./exports
    [2025-06-23 15:09:02] Taille totale des exports : 446M
    ```

### 4° Statistics
- Count of indexes : 6
- Errors : 1
- Logs : ~13M
- Output :
  ```
  ls -la exports
  total 456116
  drwxr-xr-x 2 arthubhub arthubhub      4096 Jun 23 15:09 .
  drwxr-xr-x 4 arthubhub arthubhub      4096 Jun 23 13:44 ..
  -rw-r--r-- 1 arthubhub arthubhub    346657 Jun 23 13:44 .ds-logs-generic-default-2025.06.13-000001.json.gz
  -rw-r--r-- 1 arthubhub arthubhub  47820077 Jun 23 13:52 .ds-logs-netflow-default-2025.06.13-000001.json.gz
  -rw-r--r-- 1 arthubhub arthubhub     16784 Jun 23 15:09 .ds-logs-radius-default-2025.06.13-000001.json.gz
  -rw-r--r-- 1 arthubhub arthubhub 183610222 Jun 23 14:24 .ds-logs-router_netflow-default-2025.06.13-000001.json.gz
  -rw-r--r-- 1 arthubhub arthubhub 235246670 Jun 23 15:06 .ds-logs-router_syslog-default-2025.06.13-000001.json.gz
  ```
- Duration :  `15:09:02 - 13:44:04 = 01:24:58`
- Speed : `155 000` logs per minute
  
