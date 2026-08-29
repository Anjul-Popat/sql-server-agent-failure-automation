/*
===============================================================================
File: 02-failed-job-parameter.sql

Purpose:
    Returns the names of SQL Server Agent jobs whose last recorded job-step
    outcome is Failed.

Designed for:
    SSRS Job_name parameter.

Usage:
    The Job_name parameter is populated dynamically from this dataset and
    is subsequently used by the recovery execution process.

SQL Server Agent Outcome:
    0 = Failed
===============================================================================
*/

SELECT DISTINCT
    J.name AS JobName
FROM msdb.dbo.sysjobhistory AS JH
LEFT JOIN msdb.dbo.sysjobs AS J
    ON JH.job_id = J.job_id
LEFT JOIN msdb.dbo.sysjobsteps AS JS
    ON JH.job_id = JS.job_id
WHERE JS.last_run_outcome = 0
ORDER BY J.name;
