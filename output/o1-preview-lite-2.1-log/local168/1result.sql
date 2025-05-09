SELECT AVG(jpf."salary_year_avg") AS "Average_Salary"
FROM "job_postings_fact" jpf
WHERE jpf."job_title" LIKE '%Data Analyst%'
  AND jpf."job_work_from_home" = 1
  AND jpf."job_id" IN (
    SELECT sjd."job_id"
    FROM "skills_job_dim" sjd
    WHERE sjd."skill_id" IN (
      SELECT "skill_id"
      FROM (
        SELECT sjd2."skill_id", COUNT(*) AS skill_count
        FROM "skills_job_dim" sjd2
        JOIN "job_postings_fact" jpf2 ON sjd2."job_id" = jpf2."job_id"
        WHERE jpf2."job_title" LIKE '%Data Analyst%'
          AND jpf2."job_work_from_home" = 1
        GROUP BY sjd2."skill_id"
        ORDER BY skill_count DESC
        LIMIT 3
      )
    )
  );