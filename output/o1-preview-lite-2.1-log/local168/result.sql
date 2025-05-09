WITH target_skills AS (
    SELECT sd."skill_id"
    FROM "skills_dim" sd
    WHERE sd."skills" IN ('python', 'sas', 'javascript')
),
data_analyst_jobs AS (
    SELECT jp."job_id", jp."salary_year_avg"
    FROM "job_postings_fact" jp
    WHERE jp."job_title" LIKE '%Data Analyst%'
      AND jp."job_work_from_home" = 1
      AND jp."salary_year_avg" IS NOT NULL
      AND TRIM(jp."salary_year_avg") != ''
),
job_skills AS (
    SELECT sjd."job_id", sjd."skill_id"
    FROM "skills_job_dim" sjd
    WHERE sjd."skill_id" IN (SELECT "skill_id" FROM target_skills)
),
jobs_with_skills AS (
    SELECT daj."job_id", daj."salary_year_avg"
    FROM data_analyst_jobs daj
    JOIN job_skills js ON daj."job_id" = js."job_id"
)
SELECT AVG(CAST(jws."salary_year_avg" AS REAL)) AS avg_salary
FROM jobs_with_skills jws;