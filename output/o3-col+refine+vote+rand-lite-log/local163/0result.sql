WITH avg_salary_per_rank AS (
    SELECT 
        "FacRank",
        AVG("FacSalary") AS avg_salary
    FROM "university_faculty"
    GROUP BY "FacRank"
),
salary_diff AS (
    SELECT
        f."FacRank"      AS rank,
        f."FacFirstName" AS first_name,
        f."FacLastName"  AS last_name,
        f."FacSalary"    AS salary,
        ABS(f."FacSalary" - a.avg_salary) AS diff_to_avg
    FROM "university_faculty" f
    JOIN avg_salary_per_rank a
      ON f."FacRank" = a."FacRank"
),
min_diff AS (
    SELECT 
        rank,
        MIN(diff_to_avg) AS min_diff
    FROM salary_diff
    GROUP BY rank
)
SELECT
    s.rank      AS "Rank",
    s.first_name AS "FirstName",
    s.last_name  AS "LastName",
    s.salary     AS "Salary"
FROM salary_diff s
JOIN min_diff m
  ON s.rank = m.rank
 AND s.diff_to_avg = m.min_diff
ORDER BY s.rank;