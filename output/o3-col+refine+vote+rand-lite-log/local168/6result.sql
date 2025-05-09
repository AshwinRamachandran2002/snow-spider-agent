WITH cte_da_remote AS (
    SELECT
        "job_id",
        "salary_year_avg"
    FROM "job_postings_fact"
    WHERE "job_title_short"   = 'Data Analyst'
      AND "job_work_from_home" = 1
      AND "salary_year_avg"    IS NOT NULL
),
cte_top_skills AS (
    SELECT
        sd."skill_id"
    FROM   "skills_job_dim"   AS sjd
    JOIN   cte_da_remote      AS cdr ON sjd."job_id" = cdr."job_id"
    JOIN   "skills_dim"       AS sd  ON sd."skill_id" = sjd."skill_id"
    GROUP  BY sd."skill_id"
    ORDER  BY COUNT(*) DESC
    LIMIT 3
),
cte_jobs_with_top_skills AS (
    SELECT DISTINCT
           sjd."job_id"
    FROM   "skills_job_dim" AS sjd
    JOIN   cte_top_skills   AS tts ON sjd."skill_id" = tts."skill_id"
)
SELECT 
       ROUND(AVG(cdr."salary_year_avg"), 4) AS "avg_salary_top3skills"
FROM   cte_da_remote          AS cdr
JOIN   cte_jobs_with_top_skills AS jwt ON cdr."job_id" = jwt."job_id";