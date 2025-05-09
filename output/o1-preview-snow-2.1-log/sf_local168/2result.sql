SELECT AVG(sub."salary_year_avg") AS "average_salary"
FROM (
    SELECT DISTINCT jp."job_id", jp."salary_year_avg"
    FROM CITY_LEGISLATION.CITY_LEGISLATION.JOB_POSTINGS_FACT jp
    JOIN CITY_LEGISLATION.CITY_LEGISLATION.SKILLS_JOB_DIM sjd ON jp."job_id" = sjd."job_id"
    JOIN CITY_LEGISLATION.CITY_LEGISLATION.SKILLS_DIM sd ON sjd."skill_id" = sd."skill_id"
    WHERE jp."job_work_from_home" = 1
      AND LOWER(jp."job_title") LIKE '%data analyst%'
      AND sd."skills" IN ('python', 'sas', 'javascript')
) AS sub;