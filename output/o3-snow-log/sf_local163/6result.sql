WITH rank_avg AS (   -- average salary of each rank
    SELECT 
        "FacRank",
        AVG("FacSalary") AS avg_salary
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS.UNIVERSITY_FACULTY
    GROUP BY "FacRank"
),
faculty_diff AS (    -- absolute difference from the average of the rank
    SELECT
        uf."FacRank",
        uf."FacFirstName",
        uf."FacLastName",
        uf."FacSalary",
        ABS(uf."FacSalary" - ra.avg_salary) AS diff_to_avg
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS.UNIVERSITY_FACULTY uf
    JOIN rank_avg ra
      ON uf."FacRank" = ra."FacRank"
),
min_diff AS (        -- minimum difference within each rank
    SELECT
        "FacRank",
        MIN(diff_to_avg) AS min_diff
    FROM faculty_diff
    GROUP BY "FacRank"
)
SELECT
    fd."FacRank"     AS "Rank",
    fd."FacFirstName" AS "FirstName",
    fd."FacLastName"  AS "LastName",
    fd."FacSalary"    AS "Salary"
FROM faculty_diff fd
JOIN min_diff md
  ON fd."FacRank" = md."FacRank"
 AND fd.diff_to_avg = md.min_diff
ORDER BY
    fd."FacRank",
    fd."FacLastName",
    fd."FacFirstName";