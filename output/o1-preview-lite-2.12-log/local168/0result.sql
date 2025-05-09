SELECT AVG(jp."salary_year_avg") AS Average_Salary
FROM "job_postings_fact" jp
JOIN "skills_job_dim" sj ON jp."job_id" = sj."job_id"
JOIN "skills_dim" sd ON sj."skill_id" = sd."skill_id"
WHERE jp."job_title" LIKE '%Data Analyst%'
  AND jp."job_work_from_home" = 1
  AND jp."salary_year_avg" IS NOT NULL
  AND sd."skills" IN (
    SELECT sd_top."skills"
    FROM "skills_dim" sd_top
    JOIN "skills_job_dim" sj_top ON sd_top."skill_id" = sj_top."skill_id"
    JOIN "job_postings_fact" jp_top ON sj_top."job_id" = jp_top."job_id"
    WHERE jp_top."job_title" LIKE '%Data Analyst%'
      AND jp_top."job_work_from_home" = 1
      AND jp_top."salary_year_avg" IS NOT NULL
    GROUP BY sd_top."skills"
    ORDER BY COUNT(*) DESC
    LIMIT 3
  );