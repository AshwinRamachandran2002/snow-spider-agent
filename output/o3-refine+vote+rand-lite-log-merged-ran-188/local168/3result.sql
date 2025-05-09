WITH filtered_jobs AS (
    -- Data‑Analyst postings that are remote and have a stated annual salary
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
    FROM skills_job_dim sj
    JOIN filtered_jobs fj
      ON sj.job_id = fj.job_id
    GROUP BY sj.skill_id
    ORDER BY freq DESC
    LIMIT 3          -- keep the three most frequent skills
),
jobs_with_top3_skills AS (
    -- Jobs that list at least one of the top‑3 skills
    SELECT DISTINCT
        fj.job_id,
        fj.salary_year_avg
    FROM filtered_jobs fj
    JOIN skills_job_dim sj
      ON fj.job_id = sj.job_id
    JOIN skill_frequency sf
      ON sj.skill_id = sf.skill_id
)
-- Overall average salary for those jobs
SELECT 
    AVG(salary_year_avg) AS average_remote_data_analyst_salary_top3skills
FROM jobs_with_top3_skills;