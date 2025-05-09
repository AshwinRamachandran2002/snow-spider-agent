WITH rank_avg AS (
    SELECT 
        "FacRank",
        AVG("FacSalary") AS avg_salary
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS.UNIVERSITY_FACULTY
    GROUP BY "FacRank"
),
rank_diff AS (
    SELECT 
        f."FacRank",
        f."FacFirstName",
        f."FacLastName",
        f."FacSalary",
        ABS(f."FacSalary" - ra.avg_salary) AS salary_diff
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS.UNIVERSITY_FACULTY f
    JOIN rank_avg ra
      ON f."FacRank" = ra."FacRank"
),
min_diff AS (
    SELECT 
        "FacRank",
        MIN(salary_diff) AS min_diff
    FROM rank_diff
    GROUP BY "FacRank"
)
SELECT 
    rd."FacRank"      AS rank,
    rd."FacFirstName" AS first_name,
    rd."FacLastName"  AS last_name,
    rd."FacSalary"    AS salary
FROM rank_diff rd
JOIN min_diff md
  ON rd."FacRank" = md."FacRank"
 AND rd.salary_diff = md.min_diff
ORDER BY rd."FacRank", rd."FacLastName", rd."FacFirstName";