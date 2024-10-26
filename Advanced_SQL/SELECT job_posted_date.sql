SELECT job_posted_date
FROM job_postings_fact
LIMIT 10;


SELECT
    job_title_short AS title,
    job_location AS location,
    job_posted_date AT TIME ZONE 'UTC' AT TIME ZONE 'EST' AS date,
    EXTRACT(MONTH FROM job_posted_date) AS date_month,
    EXTRACT(YEAR FROM job_posted_date) AS date_year
FROM
    job_postings_fact
LIMIT 5

SELECT
    COUNT(job_id) AS job_posted_count,
    EXTRACT(MONTH FROM job_posted_date) AS month 
FROM
    job_postings_fact
WHERE
    job_title_short = 'Data Analyst'
GROUP BY
    month
ORDER BY
    job_posted_count DESC;

--DATE functions practice
--Practice problem 1
SELECT
    job_schedule_type,
    AVG(salary_year_avg) AS yearly_avg,
    AVG(salary_hour_avg) AS hourly_avg
FROM
    job_postings_fact
WHERE
    job_posted_date > '2023-06-01'
GROUP BY
    job_schedule_type
ORDER BY
    job_schedule_type ASC;

--Practice problem 2
SELECT
    EXTRACT(MONTH FROM job_posted_date AT TIME ZONE 'UTC' AT TIME ZONE 'EST') AS month,
    COUNT(job_id) AS postings_count
FROM
    job_postings_fact
WHERE
    EXTRACT(YEAR FROM job_posted_date AT TIME ZONE 'UTC' AT TIME ZONE 'EST') = 2023
GROUP BY
    month
ORDER BY
    month;

--Practice problem 3
SELECT
    company_dim.name AS company_name,
    COUNT(job_postings_fact.job_id) AS posted_jobs_count
FROM job_postings_fact
    INNER JOIN company_dim ON job_postings_fact.company_id = company_dim.company_id
WHERE
    job_postings_fact.job_health_insurance = TRUE
    AND EXTRACT(QUARTER FROM job_postings_fact.job_posted_date AT TIME ZONE 'UTC' AT TIME ZONE 'EST') = 2
GROUP BY
    company_name
HAVING
    COUNT(job_id) > 0
ORDER BY
    posted_jobs_count DESC;


CREATE TABLE january_jobs AS
    SELECT *
    FROM job_postings_fact
    WHERE EXTRACT(MONTH FROM job_posted_date) = 1;

CREATE TABLE february_jobs AS
    SELECT *
    FROM job_postings_fact
    WHERE EXTRACT(MONTH FROM job_posted_date) = 2;

CREATE TABLE march_jobs AS
    SELECT *
    FROM job_postings_fact
    WHERE EXTRACT(MONTH FROM job_posted_date) = 3;

SELECT job_posted_date
FROM march_jobs;

--Case Expression
SELECT
    COUNT(job_id) AS number_of_jobs,
    CASE
        WHEN job_location = 'Anywhere' THEN 'Remote'
        WHEN job_location = 'New York, NY' THEN 'Local'
        ELSE 'Onsite'
    END AS location_category
FROM job_postings_fact
WHERE
    job_title_short = 'Data Analyst'
GROUP BY
    location_category;

--Case Expressions Practice Problems
--1
SELECT
    job_id,
    job_title,
    salary_year_avg,
    CASE
        WHEN salary_year_avg >= 100000 THEN 'High Salary'
        WHEN salary_year_avg BETWEEN 60000 AND 99999 THEN 'Standard Salary'
        WHEN salary_year_avg < 60000 THEN 'Low Salary'
    END AS salary_comparison
FROM
    job_postings_fact
WHERE
    salary_year_avg IS NOT NULL
    AND job_title_short = 'Data Analyst'
ORDER BY
    salary_year_avg DESC;

--2
SELECT
    COUNT(DISTINCT company_id),
    CASE
        WHEN job_work_from_home = TRUE THEN 'Remote'
        WHEN job_work_from_home = FALSE THEN 'Onsite'
    END AS remote_vs_onsite
FROM
    job_postings_fact
WHERE
    job_work_from_home IS NOT NULL
GROUP BY
    remote_vs_onsite;
--answer
SELECT
    COUNT(DISTINCT CASE WHEN job_work_from_home = TRUE THEN company_id END) AS wfh_companies,
    COUNT(DISTINCT CASE WHEN job_work_from_home = FALSE THEN company_id END) AS non_wfh_companies
FROM
    job_postings_fact;

--3
SELECT
    job_id,
    salary_year_avg,
    CASE
        WHEN job_title ILIKE '%senior%' THEN 'Senior'
        WHEN job_title ILIKE '%lead%' THEN 'Lead/Manager'
        WHEN job_title ILIKE '%manager%' THEN 'Lead/Manager'
        WHEN job_title ILIKE '%Junior%' THEN 'Junior/Entry'
        WHEN job_title ILIKE '%Entry%' THEN 'Junior/Entry'
        ELSE 'Not Specified'
    END AS experience_level,
    CASE
        WHEN job_work_from_home = TRUE THEN 'Yes'
        WHEN job_work_from_home = FALSE THEN 'No'
    END AS remote_option
FROM
    job_postings_fact;

--Subquerires and CTEs
SELECT
    company_id,
    name AS company_name
FROM
    company_dim
WHERE company_id IN (
    SELECT
        company_id
    FROM
        job_postings_fact
    WHERE
        job_no_degree_mention = TRUE
    );

WITH company_job_count AS (
SELECT
    company_id,
    COUNT(*) AS total_jobs
FROM
    job_postings_fact
GROUP BY
    company_id
    )

SELECT 
    company_dim.name AS company_name,
    company_job_count.total_jobs
FROM
    company_dim
    LEFT JOIN company_job_count ON company_job_count.company_id = company_dim.company_id
ORDER BY
    total_jobs DESC;

--Subqueries problem 1
/*Identify the top 5 skills that are most frequently mentioned in job postings. 
Use a subquery to find the skill IDs with the highest counts in the skills_job_dim table and then join this result with the skills_dim table to get the skill names.
*/
SELECT
	skills_job_dim.skill_id,
	skills_dim.name
FROM
	(
	SELECT
	skill_id
	COUNT(*) AS skill_count
	FROM
		skills_job_dim
	GROUP BY
		skill_id
	ORDER BY
		skill_count DESC
	LIMIT 5
	)
	INNER JOIN skills_dim ON skills_dim.skill_id = skills_job_dim.skill_id;
--Solution 1
/*
The subquery is used to first find the top 5 skills listed in job postings using the skills_job_dim table because there is an individual entry for
each job_id/job posting to each individual skill listed for the posting. The result will be the top 5 skills listed in job postings and can then be
joined to the skill_dim table which will supply the skill name. The INNER JOIN makes so that the only results are those that match up the 2 tables,
which is the top 5 skills from the subquery to their matching entries in the skills_dim table that have the skill names.
*/
SELECT skills_dim.skills
FROM skills_dim
        INNER JOIN (
            SELECT
                skill_id,
                COUNT(job_id) AS skill_count
            FROM
                skills_job_dim
            GROUP BY
                skill_id
            ORDER BY
                COUNT(job_id) DESC
            LIMIT 5
        ) AS top_skills ON skills_dim.skill_id = top_skills.skill_id
ORDER BY
    top_skills.skill_count DESC

--Subqueries problem 2
SELECT
    company_dim.name,
    postings_counted.post_count,
    CASE
        WHEN postings_counted.post_count < 10 THEN 'Small'
        WHEN postings_counted.post_count BETWEEN 10 AND 50 THEN 'Medium'
        WHEN postings_counted.post_count > 50 THEN 'Large'
    END AS company_size
FROM
    company_dim
    INNER JOIN
        (
        SELECT
            COUNT(job_id) AS post_count,
            company_id
        FROM
            job_postings_fact
        GROUP BY
            company_id
        ORDER BY
            COUNT(job_id) DESC
        ) AS postings_counted