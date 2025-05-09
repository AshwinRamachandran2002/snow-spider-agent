WITH filtered_jobs AS (   -- Remote Data-Analyst postings with a listed annual salary
    SELECT 
        j."job_id",
        j."salary_year_avg"
    FROM CITY_LEGISLATION.CITY_LEGISLATION."JOB_POSTINGS_FACT" j
    WHERE j."job_title_short" ILIKE '%data%analyst%'
      AND j."job_work_from_home" = 1
      AND j."salary_year_avg" IS NOT NULL
), 
skill_freq AS (          -- Frequency of each skill within those postings
    SELECT 
        sd."skills",
        COUNT(*) AS "freq"
    FROM filtered_jobs fj
    JOIN CITY_LEGISLATION.CITY_LEGISLATION."SKILLS_JOB_DIM" sj
      ON fj."job_id" = sj."job_id"
    JOIN CITY_LEGISLATION.CITY_LEGISLATION."SKILLS_DIM" sd
      ON sj."skill_id" = sd."skill_id"
    GROUP BY sd."skills"
    ORDER BY "freq" DESC NULLS LAST
    LIMIT 3              -- Top-3 most frequent skills
), 
jobs_with_top_skills AS ( -- Postings containing at least one of those top-3 skills
    SELECT DISTINCT 
        fj."job_id",
        fj."salary_year_avg"
    FROM filtered_jobs fj
    JOIN CITY_LEGISLATION.CITY_LEGISLATION."SKILLS_JOB_DIM" sj
      ON fj."job_id" = sj."job_id"
    JOIN CITY_LEGISLATION.CITY_LEGISLATION."SKILLS_DIM" sd
      ON sj."skill_id" = sd."skill_id"
    JOIN skill_freq sf
      ON sd."skills" = sf."skills"
)
SELECT 
    AVG("salary_year_avg") AS "overall_avg_salary_top3skills"
FROM jobs_with_top_skills;