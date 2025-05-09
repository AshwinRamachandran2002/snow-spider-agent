/*-------------------------------------------------------------
  Overall average annual salary for remote “Data Analyst” jobs
  that list at least ONE of the three most-frequently required
  skills for this cohort.
--------------------------------------------------------------*/
WITH filtered_jobs AS (        -- 1) Remote + salaried + Data-Analyst postings
    SELECT DISTINCT
           "job_id",
           "salary_year_avg"
    FROM   CITY_LEGISLATION.CITY_LEGISLATION.JOB_POSTINGS_FACT
    WHERE  "job_title_short" ILIKE '%data%analyst%'
      AND  "job_work_from_home" = 1
      AND  "salary_year_avg" IS NOT NULL
),
top_skills AS (                -- 2) Identify TOP-3 most requested skills
    SELECT  sd."skill_id"
    FROM    CITY_LEGISLATION.CITY_LEGISLATION.SKILLS_JOB_DIM  sj
    JOIN    filtered_jobs                                    fj  ON sj."job_id"  = fj."job_id"
    JOIN    CITY_LEGISLATION.CITY_LEGISLATION.SKILLS_DIM      sd  ON sd."skill_id" = sj."skill_id"
    GROUP BY sd."skill_id"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 3
),
jobs_with_top_skill AS (       -- 3) Keep only postings that have ≥1 of those skills
    SELECT DISTINCT
           fj."job_id",
           fj."salary_year_avg"
    FROM   filtered_jobs                                     fj
    JOIN   CITY_LEGISLATION.CITY_LEGISLATION.SKILLS_JOB_DIM  sj  ON sj."job_id"  = fj."job_id"
    JOIN   top_skills                                        ts  ON ts."skill_id" = sj."skill_id"
)
SELECT  AVG("salary_year_avg") AS "overall_avg_salary_top3skills_remote_DA"
FROM    jobs_with_top_skill;