WITH filtered_postings AS (   -- Data-Analyst, remote, with salary
    SELECT  j."job_id",
            j."salary_year_avg"
    FROM    CITY_LEGISLATION.CITY_LEGISLATION."JOB_POSTINGS_FACT" j
    WHERE   j."job_title_short" ILIKE '%data%analyst%'
      AND   j."job_work_from_home" = 1
      AND   j."salary_year_avg" IS NOT NULL
),
skill_frequencies AS (        -- Frequency of each skill within the filtered postings
    SELECT  d."skill_id",
            COUNT(*) AS "freq"
    FROM    filtered_postings            fp
    JOIN    CITY_LEGISLATION.CITY_LEGISLATION."SKILLS_JOB_DIM" sj
           ON fp."job_id" = sj."job_id"
    JOIN    CITY_LEGISLATION.CITY_LEGISLATION."SKILLS_DIM"     d
           ON sj."skill_id" = d."skill_id"
    GROUP BY d."skill_id"
),
top_three_skills AS (         -- Identify the three most frequent skills
    SELECT  "skill_id"
    FROM    skill_frequencies
    ORDER BY "freq" DESC NULLS LAST
    LIMIT   3
),
postings_with_top_skills AS ( -- Keep only postings that list at least one top-3 skill
    SELECT  DISTINCT fp."job_id",
            fp."salary_year_avg"
    FROM    filtered_postings                               fp
    JOIN    CITY_LEGISLATION.CITY_LEGISLATION."SKILLS_JOB_DIM" sj
           ON fp."job_id" = sj."job_id"
    JOIN    top_three_skills t 
           ON sj."skill_id" = t."skill_id"
)
SELECT  AVG("salary_year_avg") AS "overall_avg_salary_top3_skills"
FROM    postings_with_top_skills;