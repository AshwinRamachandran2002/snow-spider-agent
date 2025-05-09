WITH filtered_jobs AS (   -- remote “Data Analyst” ads with a listed annual salary
    SELECT 
        "job_id",
        "salary_year_avg"
    FROM CITY_LEGISLATION.CITY_LEGISLATION."JOB_POSTINGS_FACT"
    WHERE "job_title_short" ILIKE '%data%analyst%'
      AND "job_work_from_home" = 1
      AND "salary_year_avg" IS NOT NULL
),
top3_skills AS (          -- the three most-frequent skills within those ads
    SELECT 
        sj."skill_id"
    FROM filtered_jobs fj
    JOIN CITY_LEGISLATION.CITY_LEGISLATION."SKILLS_JOB_DIM" sj
      ON fj."job_id" = sj."job_id"
    GROUP BY sj."skill_id"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 3
),
jobs_with_top3 AS (       -- keep only ads that mention ≥1 of those top-3 skills
    SELECT DISTINCT
        fj."job_id",
        fj."salary_year_avg"
    FROM filtered_jobs fj
    JOIN CITY_LEGISLATION.CITY_LEGISLATION."SKILLS_JOB_DIM" sj
      ON fj."job_id" = sj."job_id"
    JOIN top3_skills t
      ON sj."skill_id" = t."skill_id"
)
SELECT 
    AVG("salary_year_avg") AS "overall_avg_salary_top3skills"
FROM jobs_with_top3;