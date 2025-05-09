WITH filtered_jobs AS (
    SELECT jp."job_id", jp."salary_year_avg"
    FROM CITY_LEGISLATION.CITY_LEGISLATION."JOB_POSTINGS_FACT" jp
    WHERE (jp."job_title" ILIKE '%Data Analyst%' OR jp."job_title_short" ILIKE '%Data Analyst%')
      AND jp."job_work_from_home" = 1
      AND jp."salary_year_avg" IS NOT NULL
),
top_skills AS (
    SELECT sd."skill_id"
    FROM CITY_LEGISLATION.CITY_LEGISLATION."SKILLS_JOB_DIM" sj
    JOIN filtered_jobs fj ON sj."job_id" = fj."job_id"
    JOIN CITY_LEGISLATION.CITY_LEGISLATION."SKILLS_DIM" sd ON sj."skill_id" = sd."skill_id"
    GROUP BY sd."skill_id"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 3
),
jobs_with_top_skills AS (
    SELECT DISTINCT fj."job_id", fj."salary_year_avg"
    FROM filtered_jobs fj
    JOIN CITY_LEGISLATION.CITY_LEGISLATION."SKILLS_JOB_DIM" sj ON fj."job_id" = sj."job_id"
    WHERE sj."skill_id" IN (SELECT "skill_id" FROM top_skills)
)
SELECT ROUND(AVG("salary_year_avg"), 4) AS "average_salary"
FROM jobs_with_top_skills;