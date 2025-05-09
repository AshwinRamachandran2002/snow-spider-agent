WITH filtered_jobs AS (
    SELECT job_id,
           salary_year_avg
    FROM job_postings_fact
    WHERE job_title_short = 'Data Analyst'     -- specifically Data Analyst roles
      AND job_work_from_home = 1              -- remote positions
      AND salary_year_avg IS NOT NULL         -- non‑null annual salary
),
job_skills AS (
    SELECT fj.job_id,
           sjd.skill_id
    FROM filtered_jobs AS fj
    JOIN skills_job_dim AS sjd
      ON fj.job_id = sjd.job_id
),
skill_counts AS (
    SELECT skill_id,
           COUNT(DISTINCT job_id) AS freq
    FROM job_skills
    GROUP BY skill_id
),
top_skills AS (
    SELECT skill_id
    FROM skill_counts
    ORDER BY freq DESC, skill_id              -- most common first
    LIMIT 3                                   -- keep top 3
),
jobs_with_top_skills AS (
    SELECT DISTINCT js.job_id
    FROM job_skills AS js
    JOIN top_skills  AS ts
      ON js.skill_id = ts.skill_id
)
SELECT ROUND(AVG(fj.salary_year_avg), 4) AS overall_average_salary
FROM filtered_jobs  AS fj
JOIN jobs_with_top_skills AS jts
  ON fj.job_id = jts.job_id;