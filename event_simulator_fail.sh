#!/bin/bash

# Replace <REPLACE-ME> with the actual webhook IDs


# Mainframe Webhook
echo "Emitting kickoff event..."
curl -X POST 'https://api.prefect.cloud/hooks/<REPLACE-ME>' -H "Content-Type: application/json" -d '{
  "event_name": "kickoff",
  "file_name": "example-file-fail.csv",
  "stage": "on-prem",
  "trackingId": "aaa89264-c79c-11eb-b8bc-0242ac140007"
}'
sleep 10


# Mainframe Webhook
echo "Emitting file transfer event..."
curl -X POST 'https://api.prefect.cloud/hooks/<REPLACE-ME>' -H "Content-Type: application/json" -d '{
  "event_name": "transfer",
  "file_name": "example-file-fail.csv",
  "stage": "distributed",
  "trackingId": "aaa89264-c79c-11eb-b8bc-0242ac140007"
}'
sleep 10


# Azure Storage Webhook
echo "Emitting storage blob created event..."
curl -X POST 'https://api.prefect.cloud/hooks/<REPLACE-ME>' -H "Content-Type: application/json" -d '[{
  "topic": "/subscriptions/{subscription-id}/resourceGroups/Storage/providers/Microsoft.Storage/storageAccounts/my-storage-account",
  "subject": "/blobServices/default/containers/test-container/blobs/new-file.txt",
  "eventType": "Microsoft.Storage.BlobCreated",
  "eventTime": "2017-06-26T18:41:00.9584103Z",
  "id": "831e1650-001e-001b-66ab-eeb76e069631",
  "data": {
    "api": "PutBlockList",
    "clientRequestId": "6d79dbfb-0e37-4fc4-981f-442c9ca65760",
    "requestId": "831e1650-001e-001b-66ab-eeb76e000000",
    "eTag": "asdf",
    "contentType": "text/plain",
    "contentLength": 524288,
    "blobType": "BlockBlob",
    "url": "https://my-storage-account.blob.core.windows.net/testcontainer/example-file-fail.csv",
    "sequencer": "00000000000004420000000000028963",
    "storageDiagnostics": {
      "batchId": "b68529f3-68cd-4744-baa4-3c0498ec19f0"
    }
  },
  "dataVersion": "",
  "metadataVersion": "1"
}]'
sleep 10


# Summary Webhook
echo "Emitting summary event..."
curl -X POST 'https://api.prefect.cloud/hooks/<REPLACE-ME>' -H "Content-Type: application/json" -d '{
  "totalRecordsSent": 123,
  "trackingId": "aaa89264-c79c-11eb-b8bc-0242ac140007"
}'
sleep 10


# Reconciliation Webhook
echo "Emitting reconciliation event..."
curl -X POST 'https://api.prefect.cloud/hooks/<REPLACE-ME>' -H "Content-Type: application/json" -d '{
  "totalRecordsReceived": 122,
  "trackingId": "aaa89264-c79c-11eb-b8bc-0242ac140007"
}'
sleep 10

echo "All events emitted successfully."