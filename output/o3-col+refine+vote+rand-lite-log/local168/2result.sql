WITH base_jobs AS (
    -- Remote Data-Analyst postings with a stated annual salary
    SELECT job_id,
           salary_year_avg
    FROM   job_postings_fact
    WHERE  job_title_short   = 'Data Analyst'
      AND  job_work_from_home = 1
      AND  salary_year_avg   IS NOT NULL
),
top3_skills AS (
    -- Top-3 most frequent skills within those postings
    SELECT sd.skills
    FROM   base_jobs      bj
    JOIN   skills_job_dim sj ON bj.job_id = sj.job_id
    JOIN   skills_dim     sd ON sj.skill_id = sd.skill_id
    GROUP  BY sd.skills
    ORDER  BY COUNT(*) DESC
    LIMIT  3
),
qualified_jobs AS (
    -- Postings that list at least one of the Top-3 skills
    SELECT DISTINCT bj.job_id
    FROM   base_jobs      bj
    JOIN   skills_job_dim sj ON bj.job_id = sj.job_id
    JOIN   skills_dim     sd ON sj.skill_id = sd.skill_id
    JOIN   top3_skills    t3 ON sd.skills = t3.skills
)
-- Overall average salary of those qualified postings
SELECT ROUND(AVG(jp.salary_year_avg), 4) AS overall_avg_salary
FROM   job_postings_fact jp
JOIN   qualified_jobs    qj ON jp.job_id = qj.job_id;