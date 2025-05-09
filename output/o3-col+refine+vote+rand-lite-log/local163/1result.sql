WITH rank_avg AS (
    SELECT 
        "FacRank",
        AVG("FacSalary") AS avg_salary
    FROM "university_faculty"
    GROUP BY "FacRank"
), diff_tbl AS (
    SELECT 
        u."FacRank",
        u."FacFirstName",
        u."FacLastName",
        u."FacSalary",
        ABS(u."FacSalary" - r.avg_salary) AS salary_diff
    FROM "university_faculty" AS u
    JOIN rank_avg AS r
      ON u."FacRank" = r."FacRank"
), min_diff AS (
    SELECT
        "FacRank",
        MIN(salary_diff) AS min_diff
    FROM diff_tbl
    GROUP BY "FacRank"
)
SELECT 
    d."FacRank",
    d."FacFirstName",
    d."FacLastName",
    d."FacSalary"
FROM diff_tbl AS d
JOIN min_diff AS m
  ON d."FacRank" = m."FacRank"
 AND d.salary_diff = m.min_diff
ORDER BY d."FacRank";