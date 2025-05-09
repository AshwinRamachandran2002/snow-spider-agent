SELECT ROUND(AVG(jpf."salary_year_avg"), 4) AS "average_salary"
FROM "CITY_LEGISLATION"."CITY_LEGISLATION"."JOB_POSTINGS_FACT" jpf
JOIN "CITY_LEGISLATION"."CITY_LEGISLATION"."SKILLS_JOB_DIM" sjd
  ON jpf."job_id" = sjd."job_id"
WHERE jpf."job_work_from_home" = 1
  AND jpf."job_title" ILIKE '%Data Analyst%'
  AND sjd."skill_id" IN (
    SELECT sjd2."skill_id"
    FROM "CITY_LEGISLATION"."CITY_LEGISLATION"."SKILLS_JOB_DIM" sjd2
    GROUP BY sjd2."skill_id"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 3
  )
  AND jpf."salary_year_avg" IS NOT NULL;