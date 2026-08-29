# Solution Architecture

## Overview

This solution automates the detection, notification, and recovery of failed SQL Server Agent jobs using:

- SQL Server Agent
- MSDB system tables
- SSRS datasets
- SSRS report parameters
- SSRS subscriptions
- Database Mail / SSRS E-Mail delivery
- `msdb.dbo.sp_start_job`

The solution follows an automated recovery cycle:

**Detect → Notify → Retrigger → Confirm → Repeat**

---

## High-Level Architecture

```text
SQL Server Agent Job
        │
        ▼
Job Execution
        │
        ▼
SQL Server Agent stores execution information
in MSDB system tables
        │
        ▼
SSRS Failure Monitoring Report
        │
        ├───────────────────────────┐
        ▼                           ▼
Failure Notification          Recovery Process
        │                           │
        ▼                           ▼
User receives failure       Failed job name is
notification                dynamically supplied
                                    │
                                    ▼
                         msdb.dbo.sp_start_job
                                    │
                                    ▼
                           Job Re-Triggered
                                    │
                                    ▼
                         User receives retrigger
                          confirmation email
                                    │
                                    ▼
                          Next Recovery Cycle
                        (e.g., every 15 minutes)
```

---------------------------------------------------------------------------------------------

Component 1: Job Execution Monitoring

SQL Server Agent records job execution information in the msdb database.
The solution uses information from the following system tables:

msdb.dbo.sysjobhistory
msdb.dbo.sysjobs
msdb.dbo.sysjobsteps
msdb.dbo.sysjobschedules

This removes the need to build and maintain a separate custom failure-tracking table.

---------------------------------------------------------------------------------------------

Component 2: Failed Job Detection

An SSRS dataset queries SQL Server Agent metadata to identify jobs with a failed run outcome.
The failed job details can include:

Job name
Job ID
Step ID
Step name
Error message
Job command
Last run outcome
Last run duration
Next scheduled run

The query accepts a configurable status parameter.

For failed jobs:
Status = 0

---------------------------------------------------------------------------------------------

Component 3: Automated Failure Notification

An SSRS subscription executes the failure monitoring report and sends an automated email to relevant users.
This removes the need for manual monitoring and manual failure communication.
Users receive failure information without waiting for a support resource to identify and communicate the issue.

---------------------------------------------------------------------------------------------

Component 4: Dynamic Failed Job Selection

A dedicated SSRS dataset returns the names of failed jobs.
The dataset is used to populate the Job_name report parameter dynamically.
The report parameter provides the job name to the recovery process.

Failed Job Dataset
        ↓
Job_name Report Parameter
        ↓
Recovery Execution Dataset

---------------------------------------------------------------------------------------------

Component 5: Automated Job Recovery

The failed job name is dynamically passed to the following command:

EXEC msdb.dbo.sp_start_job
    @job_name = @job_name;

This initiates a new execution of the SQL Server Agent job.

---------------------------------------------------------------------------------------------

Component 6: Scheduled Recovery Cycle

The recovery process is executed using an SSRS subscription.
The subscription interval is configurable.
For the reference implementation:

Every 15 minutes

At each recovery cycle, the system evaluates the current failed-job state and initiates the configured recovery action.
When a retriggered job subsequently succeeds, its current failure status is cleared and it no longer qualifies as a failed job.

---------------------------------------------------------------------------------------------

Component 7: Retrigger Confirmation

After the automated recovery process initiates the job, an SSRS subscription sends a confirmation message.

Example:
[Job Name] Job Re-Triggered

This provides visibility that the automated recovery process has initiated a retry.

---------------------------------------------------------------------------------------------

End-to-End Flow

┌──────────────────────────────┐
│ SQL Server Agent Job Fails   │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ Execution recorded in MSDB   │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ SSRS identifies failed job   │
└──────────────┬───────────────┘
               │
       ┌───────┴────────┐
       ▼                ▼
┌───────────────┐  ┌───────────────────┐
│ Failure Email │  │ Recovery Cycle    │
│ to User       │  │ via SSRS          │
└───────────────┘  └─────────┬─────────┘
                             │
                             ▼
                   ┌───────────────────┐
                   │ Select Failed Job │
                   └─────────┬─────────┘
                             │
                             ▼
                   ┌───────────────────┐
                   │ sp_start_job      │
                   └─────────┬─────────┘
                             │
                             ▼
                   ┌───────────────────┐
                   │ Job Re-Triggered  │
                   └─────────┬─────────┘
                             │
                             ▼
                   ┌───────────────────┐
                   │ Confirmation      │
                   │ Email             │
                   └───────────────────┘

---------------------------------------------------------------------------------------------

Technology Flow

| Component             | Technology               |
| --------------------- | ------------------------ |
| Job execution         | SQL Server Agent         |
| Job history           | MSDB                     |
| Failure detection     | SSRS Dataset             |
| Failure details       | SQL Server system tables |
| User notification     | SSRS Subscription        |
| Failed job selection  | SSRS Parameter           |
| Job recovery          | `sp_start_job`           |
| Retry scheduling      | SSRS Subscription        |
| Recovery confirmation | SSRS Subscription        |

---------------------------------------------------------------------------------------------

Design Principle

The solution converts a manual operational process into an exception-based automated workflow.

Before:
Monitor → Detect → Notify → Manually Retrigger

After:
Detect → Notify → Automatically Retrigger → Confirm

The objective is to minimize routine human intervention while maintaining visibility for the relevant users.



