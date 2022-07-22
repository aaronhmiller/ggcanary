from typing import Dict, List

import boto3

from ..types import ReportEntry
from .abstract_notifier import INotifier
from .format_utils import create_email_body, create_email_subject


class SESNotifier(INotifier):
    NAME = "SES"

    def __init__(self):
        self.dest_email_address = self.param("DEST_EMAIL_ADDRESS")
        self.source_email_address = self.param("SOURCE_EMAIL_ADDRESS")

    def format_report_entry(self, report_entry: ReportEntry):
        entry_header_formatted = (
            "{report_entry.username}: {len(report_entry.records)} usage occurences.\n"
            "{report_entry.tags}"
        )
        records_formatted = "\n".join(
            [
                f" - {record.sourceIPAddress} - {record.time}"
                for record in report_entry.records
            ]
        )
        return entry_header_formatted + records_formatted

    def format_message(self, report_entries: List[ReportEntry]) -> Dict:
        subject = create_email_subject(report_entries)
        body = create_email_body(report_entries)
        return {
            "Subject": {"Data": subject, "Charset": "UTF-8"},
            "Body": {"Text": {"Data": body, "Charset": "UTF-8"}},
        }

    def send_notification(self, report_entries: List[ReportEntry]):
        boto3.client("ses").send_email(
            Source=self.source_email_address,
            Destination={"ToAddresses": [self.dest_email_address]},
            Message=self.format_message(report_entries),
        )
