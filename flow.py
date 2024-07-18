from typing import Callable
from websockets.exceptions import ConnectionClosedError
import asyncio

from prefect import flow, task, get_run_logger
from prefect.events import DeploymentEventTrigger, get_events_subscriber, Event
from prefect.events.filters import (
    EventFilter,
    EventNameFilter,
    EventResourceFilter,
    ResourceSpecification,
)
from prefect.artifacts import TableArtifact

AZURE_STORAGE_BASE_URL = (
    "https://my-storage-account.blob.core.windows.net/testcontainer/"
)


@flow(flow_run_name="Event Driven Flow - {file_name}", log_prints=True)
async def event_driven_flow(file_name: str, tracking_id: str):
    print(f"tracking id: {tracking_id}")
    tracking_id_filter = EventResourceFilter(
        labels=ResourceSpecification(__root__={"trackingId": tracking_id})
    )
    file_url_filter = EventResourceFilter(
        labels=ResourceSpecification(__root__={"url": f"{AZURE_STORAGE_BASE_URL}{file_name}"})
    )

    transfer_fut = await listen_for_events_until.submit(
        EventFilter(
            event=EventNameFilter(name=["transfer"]), resource=tracking_id_filter
        ),
        until=all_events_seen,
    )

    blob_created_fut = await listen_for_events_until.submit(
        EventFilter(
            event=EventNameFilter(name=["Microsoft.Storage.BlobCreated"]),
            resource=file_url_filter,
        ),
        until=all_events_seen,
        wait_for=[transfer_fut],
    )

    summary_fut = await listen_for_events_until.submit(
        EventFilter(
            event=EventNameFilter(name=["Summary"]),
            resource=tracking_id_filter,
        ),
        until=all_events_seen,
        wait_for=[blob_created_fut],
    )
    

    reconciliation_fut = await listen_for_events_until.submit(
        EventFilter(
            event=EventNameFilter(name=["Reconciliation"]),
            resource=tracking_id_filter,
        ),
        until=all_events_seen,
        wait_for=[summary_fut],
    )
    
    summary_event = await summary_fut.result()
    reconciliation_event = await reconciliation_fut.result()

    compare_summaries(summary_event[0], reconciliation_event[0])


@task(task_run_name="Compare summaries")
def compare_summaries(summary_event: Event, reconciliation_event: Event):
    records_sent = summary_event.resource["totalRecordsSent"]
    records_received = reconciliation_event.resource["totalRecordsReceived"]
    print(f"Records sent: {records_sent}")
    print(f"Records received: {records_received}")

    if (
        summary_event.resource["totalRecordsSent"]
        != reconciliation_event.resource["totalRecordsReceived"]
    ):
        raise ValueError(f"Count of records sent and records received do not match")


@task(task_run_name="Listen for {event_filter.event.name}")
async def listen_for_events_until(
    event_filter: EventFilter, until: Callable[..., bool]
) -> list[Event]:
    """Listen for events until the provided function returns True."""
    logger = get_run_logger()
    seen_events = list()
    seen_event_names = set()
    filtered_events = set(event_filter.event.name)
    while True:
        try:
            async with get_events_subscriber(filter=event_filter) as subscriber:
                async for event in subscriber:
                    logger.info(f"📬 Received event {event.event!r}")
                    seen_event_names.add(event.event)
                    seen_events.append(event)

                    if (
                        event.event == "TransactionSummaryEvent"
                        or event.event == "TransactionReconciliationEvent"
                    ):
                        await create_event_table_artifact(event)

                    if until(seen_event_names, filtered_events):
                        return seen_events

        except ConnectionClosedError:
            logger.debug("🚨 Connection closed, reconnecting...", "red")


def all_events_seen(seen_events: set, filtered_events: set):
    """Unblocks the event listener when true."""
    return seen_events.issuperset(filtered_events)


async def create_event_table_artifact(event: Event):
    await TableArtifact(
        key=event.event.lower(),
        table=[{"Key": k, "Value": v} for k, v in event.resource.items()],
        description=f"{event.event} Details",
    ).create()


if __name__ == "__main__":
    event_driven_flow.serve(
        name="Event Driven Flow",
        triggers=[
            DeploymentEventTrigger(
                name="Kickoff",
                match={
                    "prefect.resource.id": "prefect.webhook.mainframe",
                    "stage": "on-prem",
                },
                parameters={
                    "file_name": "{{ event.resource.file_name }}",
                    "tracking_id": "{{ event.resource.trackingId }}",
                },
            )
        ],
    )
