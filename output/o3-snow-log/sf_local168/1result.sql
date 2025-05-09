WITH remote_data_analyst AS (          -- 1. Remote Data-Analyst postings with salary info
    SELECT
        "job_id",
        "salary_year_avg"
    FROM CITY_LEGISLATION.CITY_LEGISLATION."JOB_POSTINGS_FACT"
    WHERE "job_title" ILIKE '%data%analyst%'
      AND "job_work_from_home" = 1
      AND "salary_year_avg" IS NOT NULL
),

skills_frequency AS (                 -- 2. Skill frequency within that subset
    SELECT
        sd."skills",
        COUNT(*) AS "appearance_count"
    FROM CITY_LEGISLATION.CITY_LEGISLATION."SKILLS_JOB_DIM" sj
    JOIN CITY_LEGISLATION.CITY_LEGISLATION."SKILLS_DIM"     sd
          ON sj."skill_id" = sd."skill_id"
    JOIN remote_data_analyst rda
          ON rda."job_id" = sj."job_id"
    GROUP BY sd."skills"
    ORDER BY "appearance_count" DESC NULLS LAST
    LIMIT 3                           -- 3. Keep only the top-three skills
),

jobs_with_top_skills AS (             -- 4. Jobs that require ≥1 of the top-three skills
    SELECT DISTINCT sj."job_id"
    FROM CITY_LEGISLATION.CITY_LEGISLATION."SKILLS_JOB_DIM" sj
    JOIN CITY_LEGISLATION.CITY_LEGISLATION."SKILLS_DIM"     sd
          ON sj."skill_id" = sd."skill_id"
    WHERE sd."skills" IN (SELECT "skills" FROM skills_frequency)
      AND sj."job_id" IN (SELECT "job_id" FROM remote_data_analyst)
)

-- 5. Overall average salary of those jobs
SELECT
    AVG(rda."salary_year_avg") AS "avg_salary_top3skills_remote_data_analyst"
FROM remote_data_analyst rda
JOIN jobs_with_top_skills jts
      ON rda."job_id" = jts."job_id";