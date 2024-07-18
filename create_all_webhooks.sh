#!/bin/bash

# Note: change create to update if you want to update the webhook

# Create Mainframe Webhook
prefect cloud webhook create mainframe \
    --description "For emitting events from the Control-M/Mainframe side" \
    --template '{ "event": "{{ body.event_name }}", "resource": { "prefect.resource.id": "prefect.webhook.mainframe", "prefect.resource.name": "prefect.webhook.mainframe", "stage": "{{ body.stage }}", "file_name": "{{ body.file_name }}", "trackingId": "{{ body.trackingId }}" } }'

# Create Azure Storage Webhook
prefect cloud webhook create azure-storage \
    --description "For the file arrived in Azure Blob storage event" \
    --template '{ "event": "{{body[0].eventType}}", "payload": { "topic": "{{body[0].topic}}", "subject": "{{body[0].subject}}", "eventType": "{{body[0].eventType}}", "eventTime": "{{body[0].eventTime}}", "id": "{{body[0].id}}", "data": { "api": "{{body[0].data.api}}", "clientRequestId": "{{body[0].data.clientRequestId}}", "requestId": "{{body[0].data.requestId}}", "eTag": "{{body[0].data.eTag}}", "contentType": "{{body[0].data.contentType}}", "contentLength": "{{body[0].data.contentLength}}", "blobType": "{{body[0].data.blobType}}", "url": "{{body[0].data.url}}", "sequencer": "{{body[0].data.sequencer}}", "storageDiagnostics": { "batchId": "{{body[0].data.storageDiagnostics.batchId}}" } }, "dataVersion": "", "metadataVersion": "1" }, "resource": { "prefect.resource.id": "{{ body[0].data.url }}", "url": "{{body[0].data.url}}" } }'

# Create Summary Webhook
prefect cloud webhook create summary \
    --description "For the summary event originating from the event emitter" \
    --template '{ "event": "Summary", "resource": { "prefect.resource.id": "prefect.webhook.summary", "prefect.resource.name": "prefect.webhook.summary", "totalRecordsSent": "{{ body.totalRecordsSent }}", "trackingId": "{{ body.trackingId }}" } }'

# Create Reconciliation Webhook
prefect cloud webhook create reconciliation \
    --description "For the reconciliation event originating from the event consumer" \
    --template '{ "event": "Reconciliation", "resource": { "prefect.resource.id": "prefect.webhook.reconciliation", "prefect.resource.name": "prefect.webhook.reconciliation", "totalRecordsReceived": "{{ body.totalRecordsReceived }}", "trackingId": "{{ body.trackingId }}" } }'