WITH rank_avg AS (                -- 1. average salary by rank
    SELECT
        "FacRank",
        AVG("FacSalary") AS avg_salary
    FROM "university_faculty"
    GROUP BY "FacRank"
),
diffs AS (                        -- 2. absolute diff from rank average
    SELECT
        f."FacRank",
        f."FacFirstName",
        f."FacLastName",
        f."FacSalary",
        ABS(f."FacSalary" - ra.avg_salary) AS salary_diff
    FROM "university_faculty" AS f
    JOIN rank_avg AS ra
      ON f."FacRank" = ra."FacRank"
),
rank_min AS (                     -- 3. minimum diff within each rank
    SELECT
        "FacRank",
        MIN(salary_diff) AS min_diff
    FROM diffs
    GROUP BY "FacRank"
)
SELECT                             -- 4. faculty whose salary_diff = min_diff
    d."FacRank",
    d."FacFirstName",
    d."FacLastName",
    d."FacSalary"
FROM diffs AS d
JOIN rank_min AS rm
  ON d."FacRank" = rm."FacRank"
 AND d.salary_diff = rm.min_diff
ORDER BY d."FacRank";