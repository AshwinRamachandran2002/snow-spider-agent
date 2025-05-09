WITH filtered_jobs AS (
    -- Remote “Data Analyst” postings with a stated annual salary
    SELECT 
        j.job_id,
        j.salary_year_avg
    FROM job_postings_fact AS j
    WHERE j.job_title_short = 'Data Analyst'
      AND j.job_work_from_home = 1
      AND j.salary_year_avg IS NOT NULL
),
top_skills AS (
    -- Top 3 most frequently requested skills in those postings
    SELECT 
        sj.skill_id,
        COUNT(*) AS skill_freq
    FROM filtered_jobs AS f
    JOIN skills_job_dim AS sj
      ON f.job_id = sj.job_id
    GROUP BY sj.skill_id
    ORDER BY skill_freq DESC
    LIMIT 3
),
jobs_with_top_skills AS (
    -- All remote Data‑Analyst postings that require at least one of the top‑3 skills
    SELECT DISTINCT
        f.job_id,
        f.salary_year_avg
    FROM filtered_jobs AS f
    JOIN skills_job_dim AS sj
      ON f.job_id = sj.job_id
    WHERE sj.skill_id IN (SELECT skill_id FROM top_skills)
)
-- Overall average salary for those postings
SELECT 
    AVG(salary_year_avg) AS overall_average_salary
FROM jobs_with_top_skills;