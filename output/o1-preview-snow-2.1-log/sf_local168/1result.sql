SELECT AVG(jp."salary_year_avg") AS "average_salary"
FROM "CITY_LEGISLATION"."CITY_LEGISLATION"."JOB_POSTINGS_FACT" jp
JOIN "CITY_LEGISLATION"."CITY_LEGISLATION"."SKILLS_JOB_DIM" sj
  ON jp."job_id" = sj."job_id"
JOIN "CITY_LEGISLATION"."CITY_LEGISLATION"."SKILLS_DIM" sd
  ON sj."skill_id" = sd."skill_id"
WHERE jp."job_title" ILIKE '%Data Analyst%'
  AND jp."job_work_from_home" = 1
  AND sd."skills" IN ('python', 'sas', 'confluence')
  AND jp."salary_year_avg" IS NOT NULL;