WITH base_jobs AS (
    -- Data‑Analyst postings that are remote and have an annual salary
    SELECT
        "job_id",
        "salary_year_avg"
    FROM "job_postings_fact"
    WHERE "job_title_short" = 'Data Analyst'
      AND "salary_year_avg" IS NOT NULL
      AND "job_work_from_home" = 1
),
skill_counts AS (
    -- Count how often each skill occurs in those postings and keep the top 3
    SELECT
        sjd."skill_id",
        COUNT(*) AS freq
    FROM base_jobs bj
    JOIN "skills_job_dim" sjd
      ON bj."job_id" = sjd."job_id"
    GROUP BY sjd."skill_id"
    ORDER BY freq DESC
    LIMIT 3
),
jobs_with_top_skills AS (
    -- Jobs that require at least one of the top‑3 skills
    SELECT DISTINCT
        bj."job_id",
        bj."salary_year_avg"
    FROM base_jobs bj
    JOIN "skills_job_dim" sjd
      ON bj."job_id" = sjd."job_id"
    WHERE sjd."skill_id" IN (SELECT "skill_id" FROM skill_counts)
)
-- Overall average salary for those jobs
SELECT
    ROUND(AVG("salary_year_avg"), 4) AS overall_avg_salary
FROM jobs_with_top_skills;