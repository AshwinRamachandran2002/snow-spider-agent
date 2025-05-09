WITH top_skills AS (               -- 1. Find the 3 most-frequent skills
    SELECT sd.skill_id
    FROM skills_dim       AS sd
    JOIN skills_job_dim   AS sjd ON sd.skill_id = sjd.skill_id
    JOIN job_postings_fact AS jpf ON sjd.job_id = jpf.job_id
    WHERE jpf.job_title_short LIKE '%Data Analyst%'
      AND jpf.job_work_from_home = 1
      AND jpf.salary_year_avg IS NOT NULL
    GROUP BY sd.skill_id
    ORDER BY COUNT(*) DESC
    LIMIT 3
),
relevant_jobs AS (                 -- 2. Jobs that list ≥1 of those top-3 skills
    SELECT DISTINCT jpf.job_id
    FROM job_postings_fact AS jpf
    JOIN skills_job_dim   AS sjd ON jpf.job_id = sjd.job_id
    WHERE jpf.job_title_short LIKE '%Data Analyst%'
      AND jpf.job_work_from_home = 1
      AND jpf.salary_year_avg IS NOT NULL
      AND sjd.skill_id IN (SELECT skill_id FROM top_skills)
)
-- 3. Overall average salary for those jobs
SELECT ROUND(AVG(jpf.salary_year_avg), 4) AS overall_avg_salary_top3skills
FROM job_postings_fact AS jpf
WHERE jpf.job_id IN (SELECT job_id FROM relevant_jobs);