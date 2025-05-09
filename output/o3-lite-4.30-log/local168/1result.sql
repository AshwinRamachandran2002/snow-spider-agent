WITH filtered_jobs AS (
    SELECT job_id, salary_year_avg
    FROM job_postings_fact
    WHERE job_title_short = 'Data Analyst'
      AND job_work_from_home = 1
      AND salary_year_avg IS NOT NULL
),
top_three_skills AS (
    SELECT sd.skill_id
    FROM skills_dim        sd
    JOIN skills_job_dim    sjd ON sd.skill_id = sjd.skill_id
    JOIN filtered_jobs     fj  ON sjd.job_id  = fj.job_id
    GROUP BY sd.skill_id
    ORDER BY COUNT(*) DESC
    LIMIT 3
),
jobs_with_top_skills AS (
    SELECT DISTINCT sjd.job_id
    FROM skills_job_dim sjd
    WHERE sjd.skill_id IN (SELECT skill_id FROM top_three_skills)
)
SELECT ROUND(AVG(jpf.salary_year_avg), 4) AS overall_average_annual_salary
FROM job_postings_fact jpf
JOIN jobs_with_top_skills jts ON jpf.job_id = jts.job_id
WHERE jpf.job_title_short = 'Data Analyst'
  AND jpf.job_work_from_home = 1
  AND jpf.salary_year_avg IS NOT NULL;