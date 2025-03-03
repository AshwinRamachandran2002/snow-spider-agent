WITH top_skills AS (
  SELECT sd."skills"
  FROM "skills_dim" sd
  JOIN "skills_job_dim" sjd ON sd."skill_id" = sjd."skill_id"
  JOIN "job_postings_fact" jpf ON sjd."job_id" = jpf."job_id"
  WHERE jpf."job_title" LIKE '%Data Analyst%'
    AND jpf."salary_year_avg" IS NOT NULL
    AND (jpf."job_work_from_home" = 1 OR jpf."job_location" LIKE '%Remote%')
  GROUP BY sd."skills"
  ORDER BY COUNT(*) DESC
  LIMIT 3
)
SELECT AVG(jpf."salary_year_avg") AS "average_salary"
FROM "job_postings_fact" jpf
JOIN "skills_job_dim" sjd ON jpf."job_id" = sjd."job_id"
JOIN "skills_dim" sd ON sjd."skill_id" = sd."skill_id"
WHERE jpf."job_title" LIKE '%Data Analyst%'
  AND jpf."salary_year_avg" IS NOT NULL
  AND (jpf."job_work_from_home" = 1 OR jpf."job_location" LIKE '%Remote%')
  AND sd."skills" IN (SELECT "skills" FROM top_skills);