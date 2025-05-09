WITH filtered_jobs AS (
    SELECT "job_id",
           "salary_year_avg"
    FROM "job_postings_fact"
    WHERE "job_title_short" = 'Data Analyst'
      AND "job_work_from_home" = 1
      AND "salary_year_avg" IS NOT NULL
), top_skills AS (
    SELECT sj."skill_id"
    FROM "skills_job_dim" sj
    JOIN filtered_jobs fj ON fj."job_id" = sj."job_id"
    GROUP BY sj."skill_id"
    ORDER BY COUNT(*) DESC
    LIMIT 3
)
SELECT ROUND(AVG(fj."salary_year_avg"),4) AS overall_average_annual_salary
FROM filtered_jobs fj
WHERE EXISTS (
    SELECT 1
    FROM "skills_job_dim" sj
    WHERE sj."job_id" = fj."job_id"
      AND sj."skill_id" IN (SELECT "skill_id" FROM top_skills)
);