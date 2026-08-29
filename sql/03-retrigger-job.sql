/*
===============================================================================
File: 03-retrigger-job.sql

Purpose:
    Automatically retriggers a SQL Server Agent job.

Designed for:
    SSRS-based automated job recovery.

Parameter:
    @job_name - The SQL Server Agent job name dynamically supplied through
                the SSRS Job_name report parameter.

Process:
    1. SSRS identifies failed jobs.
    2. A failed job name is supplied through the Job_name parameter.
    3. sp_start_job initiates the selected SQL Server Agent job.

===============================================================================
*/

EXEC msdb.dbo.sp_start_job
    @job_name = @job_name;
