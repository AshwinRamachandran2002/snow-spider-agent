WITH avg_salary AS (
    SELECT 
        "FacRank", 
        AVG("FacSalary") AS avg_salary
    FROM "university_faculty"
    GROUP BY "FacRank"
),
diffs AS (
    SELECT
        uf."FacRank",
        uf."FacFirstName",
        uf."FacLastName",
        uf."FacSalary",
        ABS(uf."FacSalary" - a.avg_salary) AS diff_from_avg
    FROM "university_faculty" AS uf
    JOIN avg_salary AS a
      ON uf."FacRank" = a."FacRank"
),
min_diff AS (
    SELECT 
        "FacRank",
        MIN(diff_from_avg) AS min_diff
    FROM diffs
    GROUP BY "FacRank"
)
SELECT
    d."FacRank"     AS "Rank",
    d."FacFirstName" AS "FirstName",
    d."FacLastName"  AS "LastName",
    d."FacSalary"    AS "Salary"
FROM diffs AS d
JOIN min_diff AS m
  ON  d."FacRank" = m."FacRank"
  AND d.diff_from_avg = m.min_diff;