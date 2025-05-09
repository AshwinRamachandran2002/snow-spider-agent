WITH base_jobs AS (
    -- Data‑Analyst postings that are remote and list an annual salary
    SELECT
        job_id,
        salary_year_avg
    FROM job_postings_fact
    WHERE job_title_short = 'Data Analyst'
      AND job_work_from_home = 1
      AND salary_year_avg IS NOT NULL
),
top_skills AS (
    -- Count how often each skill appears in those postings and keep the top 3
    SELECT
        sj.skill_id,
        COUNT(*) AS freq
    FROM base_jobs bj
    JOIN skills_job_dim sj ON bj.job_id = sj.job_id
    GROUP BY sj.skill_id
    ORDER BY freq DESC, sj.skill_id
    LIMIT 3
),
jobs_with_top_skills AS (
    -- All distinct postings that require at least one of the top‑3 skills
    SELECT DISTINCT
        bj.job_id,
        bj.salary_year_avg
    FROM base_jobs bj
    JOIN skills_job_dim sj ON bj.job_id = sj.job_id
    WHERE sj.skill_id IN (SELECT skill_id FROM top_skills)
)
-- Overall average annual salary for those postings
SELECT ROUND(AVG(salary_year_avg), 4) AS average_salary
FROM jobs_with_top_skills;