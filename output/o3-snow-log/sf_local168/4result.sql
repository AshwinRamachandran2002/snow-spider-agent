WITH filtered_postings AS (   -- Remote Data-Analyst jobs with a stated annual salary
    SELECT 
        jp."job_id",
        jp."salary_year_avg"
    FROM CITY_LEGISLATION.CITY_LEGISLATION.JOB_POSTINGS_FACT AS jp
    WHERE jp."job_title_short" ILIKE '%data%analyst%'
      AND jp."salary_year_avg" IS NOT NULL
      AND jp."job_work_from_home" = 1
), top3_skills AS (          -- Three most-frequent skills within those postings
    SELECT 
        sd."skills"
    FROM filtered_postings fp
    JOIN CITY_LEGISLATION.CITY_LEGISLATION.SKILLS_JOB_DIM AS sj
        ON fp."job_id" = sj."job_id"
    JOIN CITY_LEGISLATION.CITY_LEGISLATION.SKILLS_DIM AS sd
        ON sj."skill_id" = sd."skill_id"
    GROUP BY sd."skills"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 3
), postings_with_top_skills AS (   -- Jobs that list at least one of the top-3 skills
    SELECT DISTINCT
        fp."job_id",
        fp."salary_year_avg"
    FROM filtered_postings fp
    JOIN CITY_LEGISLATION.CITY_LEGISLATION.SKILLS_JOB_DIM AS sj
        ON fp."job_id" = sj."job_id"
    JOIN CITY_LEGISLATION.CITY_LEGISLATION.SKILLS_DIM AS sd
        ON sj."skill_id" = sd."skill_id"
    JOIN top3_skills t3
        ON sd."skills" = t3."skills"
)
SELECT 
    AVG("salary_year_avg") AS "avg_salary_top3_skills"
FROM postings_with_top_skills;