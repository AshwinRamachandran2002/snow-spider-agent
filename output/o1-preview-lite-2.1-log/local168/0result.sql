SELECT AVG("salary_year_avg") AS "Average_Salary" FROM (
  SELECT DISTINCT jp."job_id", jp."salary_year_avg"
  FROM "job_postings_fact" jp
  JOIN "skills_job_dim" sj ON jp."job_id" = sj."job_id"
  WHERE sj."skill_id" IN (1, 7, 9)
    AND jp."job_title" LIKE '%Data Analyst%' COLLATE NOCASE
    AND jp."job_work_from_home" = 1
    AND jp."salary_year_avg" IS NOT NULL
);