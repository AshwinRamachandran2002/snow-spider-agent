WITH filtered_jobs AS (
  SELECT jpf."job_id", jpf."salary_year_avg"
  FROM CITY_LEGISLATION.CITY_LEGISLATION.JOB_POSTINGS_FACT jpf
  WHERE (jpf."job_title" ILIKE '%Data Analyst%' OR jpf."job_title_short" ILIKE '%Data Analyst%')
    AND jpf."salary_year_avg" IS NOT NULL
    AND jpf."job_work_from_home" = 1
),
top_skills AS (
  SELECT sd."skills", COUNT(*) AS "skill_count"
  FROM CITY_LEGISLATION.CITY_LEGISLATION.SKILLS_DIM sd
  JOIN CITY_LEGISLATION.CITY_LEGISLATION.SKILLS_JOB_DIM sjd ON sd."skill_id" = sjd."skill_id"
  JOIN filtered_jobs fj ON sjd."job_id" = fj."job_id"
  GROUP BY sd."skills"
  ORDER BY "skill_count" DESC NULLS LAST
  LIMIT 3
),
jobs_with_top_skills AS (
  SELECT DISTINCT fj."job_id", fj."salary_year_avg"
  FROM filtered_jobs fj
  JOIN CITY_LEGISLATION.CITY_LEGISLATION.SKILLS_JOB_DIM sjd ON fj."job_id" = sjd."job_id"
  JOIN CITY_LEGISLATION.CITY_LEGISLATION.SKILLS_DIM sd ON sjd."skill_id" = sd."skill_id"
  JOIN top_skills ts ON sd."skills" = ts."skills"
)
SELECT ROUND(AVG(jobs_with_top_skills."salary_year_avg"), 4) AS "average_salary"
FROM jobs_with_top_skills;