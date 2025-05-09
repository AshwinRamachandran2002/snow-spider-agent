WITH filtered_jobs AS (
    SELECT 
        "job_id",
        "salary_year_avg"
    FROM "job_postings_fact"
    WHERE "job_title_short" = 'Data Analyst'
      AND "job_work_from_home" = 1
      AND "salary_year_avg" IS NOT NULL
),
top3_skills AS (
    SELECT 
        sd."skill_id"
    FROM "skills_job_dim"  AS sj
    JOIN "skills_dim"      AS sd
      ON sj."skill_id" = sd."skill_id"
    WHERE sj."job_id" IN (SELECT "job_id" FROM filtered_jobs)
    GROUP BY sd."skill_id"
    ORDER BY COUNT(*) DESC
    LIMIT 3
),
jobs_with_top3 AS (
    SELECT DISTINCT
        sj."job_id"
    FROM "skills_job_dim" AS sj
    WHERE sj."skill_id" IN (SELECT "skill_id" FROM top3_skills)
)
SELECT 
    ROUND(AVG(fj."salary_year_avg"), 4) AS "overall_avg_salary_top3"
FROM filtered_jobs AS fj
JOIN jobs_with_top3 AS jt3
  ON fj."job_id" = jt3."job_id";