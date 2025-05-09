SELECT AVG("salary_year_avg") AS "average_salary"
FROM (
  SELECT DISTINCT jp."job_id", jp."salary_year_avg"
  FROM CITY_LEGISLATION.CITY_LEGISLATION."JOB_POSTINGS_FACT" jp
  JOIN CITY_LEGISLATION.CITY_LEGISLATION."SKILLS_JOB_DIM" sj
    ON jp."job_id" = sj."job_id"
  JOIN CITY_LEGISLATION.CITY_LEGISLATION."SKILLS_DIM" sd
    ON sj."skill_id" = sd."skill_id"
  WHERE (jp."job_title" LIKE '%Data Analyst%' OR jp."job_title_short" LIKE '%Data Analyst%')
    AND jp."salary_year_avg" IS NOT NULL
    AND jp."job_work_from_home" = 1
    AND sd."skills" IN (
      SELECT "skills"
      FROM (
        SELECT sd2."skills", COUNT(*) AS cnt
        FROM CITY_LEGISLATION.CITY_LEGISLATION."SKILLS_DIM" sd2
        JOIN CITY_LEGISLATION.CITY_LEGISLATION."SKILLS_JOB_DIM" sj2
          ON sd2."skill_id" = sj2."skill_id"
        JOIN CITY_LEGISLATION.CITY_LEGISLATION."JOB_POSTINGS_FACT" jp2
          ON sj2."job_id" = jp2."job_id"
        WHERE (jp2."job_title" LIKE '%Data Analyst%' OR jp2."job_title_short" LIKE '%Data Analyst%')
          AND jp2."salary_year_avg" IS NOT NULL
          AND jp2."job_work_from_home" = 1
        GROUP BY sd2."skills"
        ORDER BY cnt DESC NULLS LAST
        LIMIT 3
      )
    )
) AS filtered_jobs;