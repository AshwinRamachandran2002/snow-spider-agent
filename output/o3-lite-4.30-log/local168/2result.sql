WITH filtered AS (
    SELECT job_id,
           salary_year_avg
    FROM job_postings_fact
    WHERE job_title_short = 'Data Analyst'
      AND job_work_from_home = 1
      AND salary_year_avg IS NOT NULL
),
top_three_skills AS (
    SELECT sd.skill_id
    FROM filtered AS f
    JOIN skills_job_dim AS sj ON f.job_id = sj.job_id
    JOIN skills_dim      AS sd ON sj.skill_id = sd.skill_id
    GROUP BY sd.skill_id
    ORDER BY COUNT(*) DESC
    LIMIT 3
),
qualified_jobs AS (
    SELECT DISTINCT f.job_id,
           f.salary_year_avg
    FROM filtered      AS f
    JOIN skills_job_dim AS sj ON f.job_id = sj.job_id
    WHERE sj.skill_id IN (SELECT skill_id FROM top_three_skills)
)
SELECT printf('%.4f', AVG(salary_year_avg)) AS overall_average_annual_salary
FROM qualified_jobs;