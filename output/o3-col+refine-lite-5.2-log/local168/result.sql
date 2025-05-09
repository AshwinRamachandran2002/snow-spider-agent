WITH remote_da AS (
    -- Remote Data‑Analyst postings with a stated annual salary
    SELECT "job_id",
           "salary_year_avg"
    FROM "job_postings_fact"
    WHERE "job_title_short"     = 'Data Analyst'
      AND "job_work_from_home"  = 1
      AND "salary_year_avg"    IS NOT NULL
),
top3_skills AS (
    -- Identify the three most frequent skills in those postings
    SELECT sjd."skill_id"
    FROM "skills_job_dim" AS sjd
    JOIN remote_da          AS rd
      ON rd."job_id" = sjd."job_id"
    GROUP BY sjd."skill_id"
    ORDER BY COUNT(*) DESC
    LIMIT 3
),
qualified_jobs AS (
    -- Postings that require at least one of the TOP‑3 skills
    SELECT DISTINCT sjd."job_id"
    FROM "skills_job_dim" AS sjd
    JOIN top3_skills      AS t3
      ON sjd."skill_id" = t3."skill_id"
)
SELECT ROUND(AVG(rd."salary_year_avg"), 4) AS "overall_avg_salary_top3_skills"
FROM remote_da      AS rd
JOIN qualified_jobs AS qj
  ON rd."job_id" = qj."job_id";