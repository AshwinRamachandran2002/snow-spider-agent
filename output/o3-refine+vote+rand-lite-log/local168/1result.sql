WITH da_remote AS (
    -- 1. Data‑Analyst postings that are remote and have an annual salary
    SELECT jp.job_id,
           jp.salary_year_avg
    FROM job_postings_fact AS jp
    WHERE jp.job_title_short = 'Data Analyst'
      AND jp.job_work_from_home = 1
      AND jp.salary_year_avg IS NOT NULL
), skill_counts AS (
    -- 2. Count how often each skill appears in those postings
    SELECT sj.skill_id,
           COUNT(*) AS freq
    FROM da_remote AS dr
    JOIN skills_job_dim AS sj  ON dr.job_id = sj.job_id
    GROUP BY sj.skill_id
), top_skills AS (
    -- 3. Keep the three most frequent skills
    SELECT skill_id
    FROM skill_counts
    ORDER BY freq DESC, skill_id
    LIMIT 3
), relevant_postings AS (
    -- 4. Postings that require at least one of those top‑3 skills
    SELECT DISTINCT dr.job_id,
           dr.salary_year_avg
    FROM da_remote AS dr
    JOIN skills_job_dim AS sj
         ON dr.job_id = sj.job_id
    WHERE sj.skill_id IN (SELECT skill_id FROM top_skills)
)
-- 5. Overall average salary across those postings
SELECT AVG(salary_year_avg) AS overall_avg_salary
FROM relevant_postings;