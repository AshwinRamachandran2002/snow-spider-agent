WITH filtered_posts AS (
    -- Remote “Data Analyst” jobs that list an annual salary
    SELECT 
        job_id,
        salary_year_avg
    FROM job_postings_fact
    WHERE job_title_short    LIKE '%Data Analyst%'
      AND job_work_from_home = 1
      AND salary_year_avg    IS NOT NULL
),
top3_skills AS (
    -- Find the 3 most-frequently requested skills within those jobs
    SELECT 
        sd.skill_id
    FROM filtered_posts      fp
    JOIN skills_job_dim      sjd ON fp.job_id = sjd.job_id
    JOIN skills_dim          sd  ON sjd.skill_id = sd.skill_id
    GROUP BY sd.skill_id
    ORDER BY COUNT(*) DESC
    LIMIT 3
),
posts_with_top_skills AS (
    -- Keep only jobs that require at least one of those top-3 skills
    SELECT DISTINCT
        fp.job_id,
        fp.salary_year_avg
    FROM filtered_posts fp
    JOIN skills_job_dim sjd ON fp.job_id = sjd.job_id
    WHERE sjd.skill_id IN (SELECT skill_id FROM top3_skills)
)
-- Overall average salary for the qualifying postings
SELECT 
    ROUND(AVG(salary_year_avg),4) AS overall_avg_salary_top3skills
FROM posts_with_top_skills;