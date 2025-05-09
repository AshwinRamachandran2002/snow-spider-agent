WITH TopSkills AS (
    SELECT sd."skills"
    FROM "job_postings_fact" AS jpf
    JOIN "skills_job_dim" AS sjd ON jpf."job_id" = sjd."job_id"
    JOIN "skills_dim" AS sd ON sjd."skill_id" = sd."skill_id"
    WHERE jpf."job_title_short" = 'Data Analyst'
      AND jpf."salary_year_avg" IS NOT NULL
      AND jpf."job_work_from_home" = 1
    GROUP BY sd."skills"
    ORDER BY COUNT(*) DESC
    LIMIT 3
)
SELECT AVG(jpf."salary_year_avg") AS "Average_Salary"
FROM "job_postings_fact" AS jpf
JOIN "skills_job_dim" AS sjd ON jpf."job_id" = sjd."job_id"
JOIN "skills_dim" AS sd ON sjd."skill_id" = sd."skill_id"
WHERE jpf."job_title_short" = 'Data Analyst'
  AND jpf."salary_year_avg" IS NOT NULL
  AND jpf."job_work_from_home" = 1
  AND sd."skills" IN (SELECT "skills" FROM TopSkills);