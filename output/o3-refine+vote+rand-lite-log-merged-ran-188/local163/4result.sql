WITH avg_salary_by_rank AS (
    SELECT
        "FacRank",
        AVG("FacSalary") AS avg_salary
    FROM "university_faculty"
    GROUP BY "FacRank"
),
salary_diffs AS (
    SELECT
        f."FacRank",
        f."FacFirstName",
        f."FacLastName",
        f."FacSalary",
        ABS(f."FacSalary" - a.avg_salary) AS diff_from_avg
    FROM "university_faculty" f
    JOIN avg_salary_by_rank a
      ON f."FacRank" = a."FacRank"
),
min_diff_per_rank AS (
    SELECT
        "FacRank",
        MIN(diff_from_avg) AS min_diff
    FROM salary_diffs
    GROUP BY "FacRank"
)
SELECT
    s."FacRank",
    s."FacFirstName",
    s."FacLastName",
    s."FacSalary"
FROM salary_diffs s
JOIN min_diff_per_rank m
  ON s."FacRank" = m."FacRank"
 AND s.diff_from_avg = m.min_diff
ORDER BY
    s."FacRank",
    s."FacLastName",
    s."FacFirstName";