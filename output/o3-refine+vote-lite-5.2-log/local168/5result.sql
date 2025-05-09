WITH remote_data_analyst_jobs AS (
    SELECT job_id,
           salary_year_avg
    FROM job_postings_fact
    WHERE LOWER(job_title_short) = 'data analyst'
      AND job_work_from_home = 1
      AND salary_year_avg IS NOT NULL
),
job_skills AS (
    SELECT r.job_id,
           sj.skill_id
    FROM remote_data_analyst_jobs r
    JOIN skills_job_dim sj
      ON r.job_id = sj.job_id
),
top_skills AS (
    SELECT skill_id
    FROM job_skills
    GROUP BY skill_id
    ORDER BY COUNT(*) DESC
    LIMIT 3
),
jobs_with_top_skills AS (
    SELECT DISTINCT js.job_id
    FROM job_skills js
    JOIN top_skills ts
      ON js.skill_id = ts.skill_id
)
SELECT AVG(r.salary_year_avg) AS average_salary
FROM remote_data_analyst_jobs r
JOIN jobs_with_top_skills j
  ON r.job_id = j.job_id;