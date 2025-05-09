WITH avg_per_rank AS (
    SELECT 
        "FacRank" AS rank,
        AVG("FacSalary") AS avg_salary
    FROM "university_faculty"
    GROUP BY "FacRank"
),
salary_diff AS (
    SELECT
        f."FacRank"        AS rank,
        f."FacFirstName"   AS first_name,
        f."FacLastName"    AS last_name,
        f."FacSalary"      AS salary,
        ABS(f."FacSalary" - a.avg_salary) AS diff_from_avg
    FROM "university_faculty" f
    JOIN avg_per_rank a
      ON f."FacRank" = a.rank
),
min_diff AS (
    SELECT
        rank,
        MIN(diff_from_avg) AS min_diff
    FROM salary_diff
    GROUP BY rank
)
SELECT
    s.rank,
    s.first_name,
    s.last_name,
    s.salary
FROM salary_diff s
JOIN min_diff m
  ON s.rank = m.rank
 AND s.diff_from_avg = m.min_diff
ORDER BY s.rank, s.last_name, s.first_name;