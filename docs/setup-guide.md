# Setup Guide

This guide explains how to configure the SSRS-based SQL Server Agent job failure monitoring and automated recovery solution.

The reference implementation follows this process:

**Detect → Notify → Retrigger → Confirm → Repeat**

> **Important:** Test this solution in a non-production environment before enabling automated recovery for production jobs.

---

# Prerequisites

Before configuring the solution, verify that the following components are available:

- SQL Server Agent is enabled and running.
- SSRS is configured and accessible.
- An SSRS data source can connect to the SQL Server instance hosting the `msdb` database.
- SSRS E-Mail delivery is configured.
- The account used by the SSRS data source has the required permissions to:
  - Read SQL Server Agent metadata from `msdb`.
  - Execute `msdb.dbo.sp_start_job` for the intended jobs.
- The SSRS subscription schedule is configured.

---

# Step 1: Create the SSRS Data Source

Create a data source for the SQL Server instance where SQL Server Agent jobs are running.

The connection must be able to access:

```text
msdb
```

The solution retrieves SQL Server Agent metadata from `msdb` system tables.

Depending on the environment, use either:

- Windows Integrated Security
- A dedicated SQL Server or domain service account

## Recommended Permission Principle

Follow the principle of least privilege.

The account should have only the permissions required to:

1. Read the required job metadata.
2. Execute the approved SQL Server Agent jobs.

Avoid using unnecessary high-privilege accounts.

---

# Step 2: Create the Failure Monitoring Dataset

Create an SSRS dataset using:

```text
sql/01-failed-job-details.sql
```

The query retrieves job information including:

- Job name
- Job ID
- Step ID
- Step name
- Error message
- Job command
- Last run outcome
- Last run duration
- Next scheduled run information

Create a report parameter:

```text
Status
```

The parameter can be used to filter jobs based on their SQL Server Agent run outcome.

For failed jobs:

```text
Status = 0
```

The `Status` parameter can be configured as a multi-value parameter if required.

---

# Step 3: Create the Failed Job Name Dataset

Create another SSRS dataset using:

```text
sql/02-failed-job-parameter.sql
```

This dataset dynamically returns the names of jobs that qualify for the recovery process.

The output is used to populate the SSRS report parameter:

```text
Job_name
```

The relationship is:

```text
Failed Job Dataset
        ↓
Job_name Parameter
        ↓
Job Recovery Execution
```

---

# Step 4: Configure the Job_name Report Parameter

Create the report parameter:

```text
Job_name
```

## Parameter Configuration

### Available Values

Configure the parameter to get values from a query.

Select:

```text
Dataset: Job_Name
Value field: JobName
```

### Default Values

Configure:

```text
Get values from a query
```

Select:

```text
Dataset: Job_Name
Value field: JobName
```

This allows the parameter values to be dynamically populated based on the failed job query.

If multiple jobs are returned, configure and validate the recovery process according to the intended one-job-at-a-time execution behavior.

---

# Step 5: Create the Job Recovery Execution Dataset

Create an SSRS dataset using:

```text
sql/03-retrigger-job.sql
```

The execution command is:

```sql
EXEC msdb.dbo.sp_start_job
    @job_name = @job_name;
```

Map the SSRS parameter to the dataset parameter:

```text
SSRS Parameter        Dataset Parameter
----------------------------------------
Job_name              @job_name
```

The selected job name is dynamically passed to the SQL Server Agent stored procedure.

The procedure then initiates a new execution of the specified job.

---

# Step 6: Configure the Failure Notification Subscription

Create an SSRS E-Mail subscription for the failure monitoring report.

Configure the subscription to:

1. Execute the failure monitoring report.
2. Filter the report for failed job status.
3. Send the failure information to the relevant users.

Example notification subject:

```text
SQL Server Agent Job Failure Alert
```

The notification should provide sufficient information for users to understand the failure.

Recommended information includes:

- Job name
- Failed step
- Error message
- Last run information
- Next scheduled run

---

# Step 7: Configure the Automated Recovery Subscription

Create an SSRS subscription to initiate the automated recovery process.

The recovery interval is configurable.

Example:

```text
Every 15 minutes
```

During each recovery cycle, the solution:

1. Evaluates the current failed-job state.
2. Obtains the configured failed job name.
3. Passes the job name to the recovery execution dataset.
4. Executes `msdb.dbo.sp_start_job`.

The job is then re-triggered automatically.

---

# Step 8: Configure the Retrigger Confirmation

After the recovery process initiates the job, send a confirmation message through an SSRS subscription.

Example message:

```text
[Job Name] Job Re-Triggered
```

This provides operational visibility that the retry process has been initiated.

> This confirmation indicates that the job was re-triggered. It does not by itself confirm that the job subsequently completed successfully.

---

# Step 9: Validate the Recovery Cycle

Test the complete solution using a controlled test job.

Recommended validation process:

```text
1. Trigger a controlled job failure.
          ↓
2. Verify that the failure is captured.
          ↓
3. Verify that the failure notification is received.
          ↓
4. Verify that the failed job is identified by the Job_name parameter.
          ↓
5. Run the recovery process.
          ↓
6. Verify that the job is re-triggered.
          ↓
7. Verify that the retrigger confirmation is received.
          ↓
8. Verify the subsequent job outcome.
          ↓
9. Confirm that a successfully recovered job no longer qualifies
   for the failed-job recovery process.
```

---

# Recovery Interval

The recovery interval should be selected based on:

- Job criticality
- Average job duration
- Expected recovery time
- Dependency between jobs
- Server capacity
- Risk of repeated executions

The reference implementation uses:

```text
15 minutes
```

However, the interval should be configurable for different environments.

Avoid setting the interval so low that the same job could be re-triggered while a previous execution is still running.

---

# Security Considerations

Automated job recovery should be configured carefully.

Recommended controls include:

- Restrict the SSRS execution account to approved jobs.
- Avoid using `sysadmin` privileges where not required.
- Validate the SSRS report parameters.
- Test the solution before production deployment.
- Consider excluding jobs that should never be automatically retried.
- Monitor repeated failures.
- Review the permissions required by `sp_start_job`.
- Consider limiting the maximum number of automated retry attempts.

---

# Recommended Operational Enhancements

The reference implementation provides automated detection and recovery.

For a more mature production implementation, consider adding:

- Maximum retry count
- Retry history
- Failure escalation
- Exclusion list for sensitive jobs
- Job dependency awareness
- Recovery audit logging
- Alerting after repeated failures
- Recovery success notification
- Automatic escalation when recovery fails

---

# Troubleshooting

## Job does not appear in the Job_name parameter

Check:

1. The job has actually failed.
2. The SSRS parameter dataset returns the expected job name.
3. The dataset and parameter configuration is correct.
4. The SSRS data source has access to `msdb`.
5. The report is refreshed using current job metadata.

---

## Job does not re-trigger

Check:

1. The `Job_name` value is correctly passed to `@job_name`.
2. The job name exists in SQL Server Agent.
3. SQL Server Agent is running.
4. The execution account has permission to start the job.
5. The job is not already running.

---

## E-Mail is not received

Check:

1. SSRS E-Mail delivery configuration.
2. SSRS subscription status.
3. Recipient addresses.
4. Subscription execution history.
5. Mail server configuration.

---

# Implementation Summary

The solution uses existing SQL Server and SSRS capabilities to automate a traditionally manual operational process.

```text
Manual Process

Monitor
   ↓
Identify Failure
   ↓
Inform User
   ↓
Manually Re-Trigger Job
```

```text
Automated Process

Detect
   ↓
Notify
   ↓
Dynamically Identify Failed Job
   ↓
Automatically Re-Trigger
   ↓
Confirm Re-Trigger
   ↓
Repeat at Configured Interval
```

The objective is to reduce manual operational effort, shorten recovery time, and provide a more consistent response to recurring job failures.
