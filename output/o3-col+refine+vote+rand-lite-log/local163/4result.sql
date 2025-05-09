WITH avg_rank AS (
    SELECT 
        "FacRank",
        AVG("FacSalary") AS avg_salary
    FROM "university_faculty"
    GROUP BY "FacRank"
),
diffs AS (
    SELECT
        f."FacRank",
        f."FacFirstName",
        f."FacLastName",
        f."FacSalary",
        ABS(f."FacSalary" - a.avg_salary) AS diff_from_avg
    FROM "university_faculty" AS f
    JOIN avg_rank AS a
      ON f."FacRank" = a."FacRank"
),
min_diff AS (
    SELECT
        "FacRank",
        MIN(diff_from_avg) AS min_diff
    FROM diffs
    GROUP BY "FacRank"
)
SELECT
    d."FacRank",
    d."FacFirstName",
    d."FacLastName",
    d."FacSalary"
FROM diffs AS d
JOIN min_diff AS m
  ON d."FacRank" = m."FacRank"
 AND d.diff_from_avg = m.min_diff
ORDER BY d."FacRank", d."FacLastName", d."FacFirstName";