# SQL Server Agent Failure Automation

An automated solution for detecting failed SQL Server Agent jobs, notifying users, and automatically re-triggering failed jobs using SQL Server Agent metadata and SSRS subscriptions.

## Overview

SQL Server Agent job failures often require manual operational intervention:

```text
Monitor Job Failure
        ↓
Identify Failed Job
        ↓
Investigate Failure
        ↓
Notify User
        ↓
Manually Re-Trigger Job
```

This solution automates the repetitive portions of that process.

```text
Detect
   ↓
Notify
   ↓
Identify Failed Job
   ↓
Automatically Re-Trigger
   ↓
Confirm Re-Trigger
   ↓
Repeat at Configured Interval
```

The objective is to reduce manual intervention, improve response time, and provide consistent operational visibility.

---

## Solution Architecture

The solution uses:

- SQL Server Agent
- MSDB system tables
- SSRS datasets
- SSRS report parameters
- SSRS subscriptions
- SSRS E-Mail delivery
- `msdb.dbo.sp_start_job`

The automated recovery cycle is:

**Detect → Notify → Retrigger → Confirm → Repeat**

### High-Level Flow

```text
SQL Server Agent Job
        │
        ▼
Job Execution
        │
        ▼
Execution Information Recorded in MSDB
        │
        ▼
SSRS Failure Monitoring
        │
        ├───────────────────────────┐
        ▼                           ▼
Failure Notification          Recovery Process
        │                           │
        ▼                           ▼
User Receives Failure       Failed Job Identified
Notification                       │
                                   ▼
                         msdb.dbo.sp_start_job
                                   │
                                   ▼
                           Job Re-Triggered
                                   │
                                   ▼
                         Re-Trigger Confirmation
                                   │
                                   ▼
                         Next Recovery Cycle
                      (e.g., every 15 minutes)
```

---

## Key Features

### 🔍 Automated Failure Detection

Failed SQL Server Agent jobs are identified using existing metadata stored in the `msdb` database.

The solution uses SQL Server Agent system tables including:

- `msdb.dbo.sysjobhistory`
- `msdb.dbo.sysjobs`
- `msdb.dbo.sysjobsteps`
- `msdb.dbo.sysjobschedules`

This avoids the need to create and maintain a separate custom failure-tracking table.

---

### 📧 Automated Failure Notification

SSRS subscriptions send automated failure notifications to relevant users.

This improves visibility and removes the need for manual failure communication.

---

### 🎯 Dynamic Failed Job Selection

A dedicated SSRS dataset dynamically identifies failed jobs.

The failed job name is then supplied through an SSRS report parameter:

```text
Failed Job Dataset
        ↓
Job_name Parameter
        ↓
Recovery Execution
```

---

### 🔄 Automated Job Recovery

The failed job is automatically re-triggered using:

```sql
EXEC msdb.dbo.sp_start_job
    @job_name = @job_name;
```

The `Job_name` parameter dynamically supplies the job selected for recovery.

---

### ⏱️ Configurable Recovery Cycle

The recovery process is executed through SSRS subscriptions.

The reference implementation uses:

```text
Every 15 minutes
```

The recovery interval can be adjusted according to:

- Job criticality
- Job duration
- Expected recovery time
- Server capacity
- Job dependencies

---

### 📬 Re-Trigger Confirmation

After the recovery process initiates the job, an automated confirmation message can be sent.

Example:

```text
[Job Name] Job Re-Triggered
```

> This confirms that the retry was initiated. It does not by itself confirm that the job subsequently completed successfully.

---

## Lean Automation Mindset

This project applies Lean principles to an operational support process.

### Before Automation

```text
Monitor
   ↓
Detect
   ↓
Notify
   ↓
Manually Re-Trigger
```

This process involved recurring manual monitoring and intervention.

### After Automation

```text
Detect
   ↓
Notify
   ↓
Automatically Re-Trigger
   ↓
Confirm
```

### Lean Benefits

- Reduction of manual operational activity
- Reduction of waiting time before recovery
- Faster response to job failures
- Standardized recovery process
- Improved operational visibility
- Reduced dependency on manual monitoring
- Better use of support resources
- Exception-based operations instead of routine manual checks

The solution focuses human effort on genuine exceptions rather than repetitive operational activities.

---

## Approximate Time Savings

Based on the current operational pattern:

| Metric | Estimate |
|---|---:|
| Average failed jobs | 22 per month |
| Average manual effort per failure | 15 minutes |
| Total monthly manual effort | **330 minutes** |
| Total monthly manual effort | **5.5 hours** |
| Annual estimated manual effort | **66 hours** |

### Calculation

```text
22 failures × 15 minutes
= 330 minutes per month

330 ÷ 60
= 5.5 hours per month

5.5 × 12
= 66 hours per year
```

### Estimated Benefit

The automation has the potential to eliminate or significantly reduce approximately:

**5.5 hours of recurring manual effort per month**

or:

**66 hours per year**

These estimates are based on the average failure volume and manual effort provided for the reference implementation. Actual savings will depend on failure frequency, job behavior, and the level of manual intervention still required for exceptions.

---

## Repository Structure

```text
sql-server-agent-failure-automation/
│
├── docs/
│   ├── architecture.md
│   └── setup-guide.md
│
├── sql/
│   ├── 01-failed-job-details.sql
│   ├── 02-failed-job-parameter.sql
│   └── 03-retrigger-job.sql
│
├── .gitignore
├── LICENSE
└── README.md
```

---

## SQL Scripts

### `01-failed-job-details.sql`

Retrieves SQL Server Agent job details for monitoring and failure reporting.

The dataset can return information including:

- Job name
- Job ID
- Step ID
- Step name
- Error message
- Job command
- Last run outcome
- Last run duration
- Next scheduled run information

---

### `02-failed-job-parameter.sql`

Returns the failed job names used to dynamically populate the SSRS job parameter.

This enables the recovery process to select the current failed job without manually maintaining job names.

---

### `03-retrigger-job.sql`

Re-triggers the selected SQL Server Agent job using:

```sql
EXEC msdb.dbo.sp_start_job
    @job_name = @job_name;
```

---

## How It Works

```text
1. SQL Server Agent job fails
          ↓
2. Failure information is available in MSDB
          ↓
3. SSRS identifies the failed job
          ↓
4. User receives failure notification
          ↓
5. Failed job name is dynamically selected
          ↓
6. SSRS passes the job name to sp_start_job
          ↓
7. Job is automatically re-triggered
          ↓
8. User receives re-trigger confirmation
          ↓
9. Recovery process repeats at the configured interval
```

---

## Documentation

Detailed documentation is available in the following files:

- [Solution Architecture](docs/architecture.md)
- [Setup Guide](docs/setup-guide.md)

---

## Prerequisites

Before implementing the solution, verify that:

- SQL Server Agent is enabled and running.
- SSRS is configured and accessible.
- SSRS can connect to the SQL Server instance hosting `msdb`.
- SSRS E-Mail delivery is configured.
- The SSRS execution account has the required permissions.
- The required SQL Server Agent jobs can be started by the execution account.
- The solution has been tested before production deployment.

---

## Important Considerations

Automated recovery should be implemented carefully.

Consider the following:

- Some jobs should not be automatically re-triggered.
- A job should not be re-triggered while it is already running.
- Job dependencies should be considered.
- Repeated failures may require escalation rather than continuous retries.
- Sensitive jobs may require manual approval.
- The execution account should follow the principle of least privilege.

For production environments, consider adding:

- Maximum retry count
- Retry history
- Audit logging
- Failure escalation
- Recovery success notification
- Exclusion list for selected jobs
- Job dependency validation
- Alerting after repeated failures

---

## Security

The account executing the recovery process should be restricted to the minimum permissions required.

Recommended practices:

- Use least-privilege access.
- Avoid unnecessary `sysadmin` permissions.
- Validate dynamically supplied job names.
- Restrict automated recovery to approved jobs.
- Review permissions required for `msdb.dbo.sp_start_job`.
- Test thoroughly before production deployment.

---

## Project Goal

This project demonstrates how existing SQL Server and SSRS capabilities can be combined to convert a repetitive manual support activity into an automated, exception-based operational workflow.

The goal is not only to re-trigger failed jobs automatically, but to improve the overall operational process by:

- Reducing manual effort
- Reducing response time
- Standardizing recovery actions
- Maintaining user visibility
- Allowing support teams to focus on failures that require human analysis

---

## Future Enhancements

Potential future improvements include:

- Maximum retry limit
- Automatic escalation after repeated failures
- Recovery success confirmation
- Retry audit history
- Dashboard for failure and recovery trends
- Job-specific retry rules
- Exclusion lists
- Dependency-aware recovery
- Automatic incident creation
- Monitoring and reporting of automation time savings

---

## License

This project is available under the terms of the included [LICENSE](LICENSE) file.

---

## Contributing

Suggestions, improvements, and enhancements are welcome.

If you encounter a similar SQL Server Agent failure-monitoring or recovery requirement, feel free to adapt the solution to your environment.

---

⭐ If you find this project useful, consider starring the repository.
