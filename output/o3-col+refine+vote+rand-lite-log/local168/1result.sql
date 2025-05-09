WITH remote_da_jobs AS (
    SELECT 
        job_id,
        salary_year_avg
    FROM job_postings_fact
    WHERE job_title_short      = 'Data Analyst'
      AND job_work_from_home   = 1
      AND salary_year_avg IS NOT NULL
),
top_three_skills AS (
    SELECT 
        sjd.skill_id
    FROM skills_job_dim AS sjd
    JOIN remote_da_jobs AS rdj
      ON rdj.job_id = sjd.job_id
    GROUP BY sjd.skill_id
    ORDER BY COUNT(*) DESC
    LIMIT 3
),
jobs_with_top_skills AS (
    SELECT DISTINCT 
        rdj.job_id,
        rdj.salary_year_avg
    FROM remote_da_jobs AS rdj
    JOIN skills_job_dim AS sjd
      ON sjd.job_id = rdj.job_id
    WHERE sjd.skill_id IN (SELECT skill_id FROM top_three_skills)
)
SELECT 
    ROUND(AVG(salary_year_avg), 4) AS overall_avg_salary_top3_skills
FROM jobs_with_top_skills;