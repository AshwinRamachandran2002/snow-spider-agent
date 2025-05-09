WITH filtered_jobs AS (        -- Remote “Data Analyst” postings with a salary
    SELECT  jp."job_id",
            jp."salary_year_avg"
    FROM    CITY_LEGISLATION.CITY_LEGISLATION.JOB_POSTINGS_FACT jp
    WHERE   jp."job_title_short" ILIKE '%data%analyst%'
      AND   jp."salary_year_avg" IS NOT NULL
      AND   jp."job_work_from_home" = 1
),
top3_skills AS (               -- Three most frequently requested skills
    SELECT  sd."skill_id"
    FROM    filtered_jobs                 fj
    JOIN    CITY_LEGISLATION.CITY_LEGISLATION.SKILLS_JOB_DIM sj
           ON fj."job_id" = sj."job_id"
    JOIN    CITY_LEGISLATION.CITY_LEGISLATION.SKILLS_DIM     sd
           ON sj."skill_id" = sd."skill_id"
    GROUP BY sd."skill_id"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 3
),
salary_sample AS (             -- Postings that ask for *any* of those 3 skills
    SELECT  DISTINCT fj."job_id",
            fj."salary_year_avg"
    FROM    filtered_jobs                 fj
    JOIN    CITY_LEGISLATION.CITY_LEGISLATION.SKILLS_JOB_DIM sj
           ON fj."job_id" = sj."job_id"
    WHERE   sj."skill_id" IN (SELECT "skill_id" FROM top3_skills)
)
SELECT  AVG("salary_year_avg") AS "avg_salary_top3skills"
FROM    salary_sample;