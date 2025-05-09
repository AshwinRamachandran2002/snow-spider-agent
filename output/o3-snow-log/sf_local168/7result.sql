/* 1) Isolate remote Data-Analyst postings with a non-NULL annual salary         */
WITH filtered_jobs AS (  
    SELECT 
        "job_id",
        "salary_year_avg"
    FROM CITY_LEGISLATION.CITY_LEGISLATION.JOB_POSTINGS_FACT
    WHERE "job_title_short" ILIKE '%data%analyst%'
      AND "job_work_from_home" = 1
      AND "salary_year_avg" IS NOT NULL
),

/* 2) Attach their skill names                                                   */
job_skills AS (   
    SELECT 
        fj."job_id",
        sd."skills"
    FROM filtered_jobs                                   fj
    JOIN CITY_LEGISLATION.CITY_LEGISLATION.SKILLS_JOB_DIM sj ON fj."job_id" = sj."job_id"
    JOIN CITY_LEGISLATION.CITY_LEGISLATION.SKILLS_DIM     sd ON sj."skill_id" = sd."skill_id"
),

/* 3) Derive the three most-frequently requested skills (by distinct jobs)       */
top3_skills AS (   
    SELECT "skills"
    FROM (
        SELECT 
            "skills",
            COUNT(DISTINCT "job_id") AS job_cnt
        FROM job_skills
        GROUP BY "skills"
        ORDER BY job_cnt DESC NULLS LAST
        LIMIT 3
    )
),

/* 4) Identify jobs that require ANY of those top-3 skills                       */
eligible_jobs AS (  
    SELECT DISTINCT "job_id"
    FROM job_skills
    WHERE "skills" IN (SELECT "skills" FROM top3_skills)
)

/* 5) Compute the overall average salary for the eligible jobs                   */
SELECT 
    AVG(fj."salary_year_avg") AS "overall_avg_salary_top3skills"
FROM filtered_jobs fj
WHERE fj."job_id" IN (SELECT "job_id" FROM eligible_jobs);