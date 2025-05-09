WITH data_analyst_remote AS (
    -- Data‑Analyst postings that are remote and have an annual salary
    SELECT 
        job_id,
        salary_year_avg
    FROM job_postings_fact
    WHERE job_title_short = 'Data Analyst'
      AND job_work_from_home = 1
      AND salary_year_avg IS NOT NULL
),
skill_frequency AS (
    -- Count how often each skill appears in those postings
    SELECT 
        sj.skill_id,
        COUNT(*) AS freq
    FROM data_analyst_remote AS dar
    JOIN skills_job_dim AS sj
      ON dar.job_id = sj.job_id
    GROUP BY sj.skill_id
    ORDER BY freq DESC, sj.skill_id
    LIMIT 3            -- keep the three most frequently requested skills
),
relevant_jobs AS (
    -- Jobs that require at least one of the top‑3 skills
    SELECT DISTINCT 
        dar.job_id,
        dar.salary_year_avg
    FROM data_analyst_remote AS dar
    JOIN skills_job_dim AS sj
      ON dar.job_id = sj.job_id
    WHERE sj.skill_id IN (SELECT skill_id FROM skill_frequency)
)
-- Overall average salary for those jobs
SELECT 
    AVG(salary_year_avg) AS overall_avg_salary
FROM relevant_jobs;