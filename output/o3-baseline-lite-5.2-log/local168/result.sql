WITH da_remote AS (
    -- Data‑Analyst postings that mention an annual salary and are remote
    SELECT 
        "job_id",
        "salary_year_avg"
    FROM "job_postings_fact"
    WHERE UPPER("job_title_short") = 'DATA ANALYST'
      AND "salary_year_avg" IS NOT NULL
      AND "job_work_from_home" = 1
),
skill_frequency AS (
    -- How often each skill is requested in those postings
    SELECT 
        sj."skill_id",
        COUNT(*) AS freq
    FROM da_remote dr
    JOIN "skills_job_dim" sj
      ON dr."job_id" = sj."job_id"
    GROUP BY sj."skill_id"
    ORDER BY freq DESC, sj."skill_id" ASC
    LIMIT 3                      -- top three most frequent skills
),
eligible_jobs AS (
    -- Job postings that require at least one of those top‑3 skills
    SELECT DISTINCT
        dr."job_id",
        dr."salary_year_avg"
    FROM da_remote dr
    JOIN "skills_job_dim" sj
      ON dr."job_id" = sj."job_id"
    WHERE sj."skill_id" IN (SELECT "skill_id" FROM skill_frequency)
)
-- overall average annual salary among those postings
SELECT AVG("salary_year_avg") AS overall_avg_salary
FROM eligible_jobs;