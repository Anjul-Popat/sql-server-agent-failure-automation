/*
===============================================================================
File: 01-failed-job-details.sql

Purpose:
    Retrieves detailed information about SQL Server Agent jobs based on
    their last recorded run outcome.

Designed for:
    SSRS failure monitoring and notification.

Parameters:
    @Status - SQL Server Agent job outcome status.
              Example: 0 = Failed

System tables used:
    msdb.dbo.sysjobhistory
    msdb.dbo.sysjobs
    msdb.dbo.sysjobsteps
    msdb.dbo.sysjobschedules
===============================================================================
*/

SELECT
    JH.job_id,
    JH.step_id,
    JH.step_name,
    JH.message,
    J.name,
    J.date_created,
    J.date_modified,
    JS.command,
    JS.last_run_outcome,
    JS.last_run_duration,
    JS.last_run_date,
    JS.last_run_time,
    JSCH.next_run_date,
    JSCH.next_run_time
FROM msdb.dbo.sysjobhistory AS JH
LEFT JOIN msdb.dbo.sysjobs AS J
    ON JH.job_id = J.job_id
LEFT JOIN msdb.dbo.sysjobsteps AS JS
    ON JH.job_id = JS.job_id
LEFT JOIN msdb.dbo.sysjobschedules AS JSCH
    ON JH.job_id = JSCH.job_id
WHERE JS.last_run_outcome IN (@Status);
