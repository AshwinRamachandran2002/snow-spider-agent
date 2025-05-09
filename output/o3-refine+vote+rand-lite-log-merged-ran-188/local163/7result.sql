WITH rank_avg AS (
    SELECT 
        "FacRank",
        AVG("FacSalary") AS avg_salary
    FROM "university_faculty"
    GROUP BY "FacRank"
),
faculty_diff AS (
    SELECT 
        f."FacRank",
        f."FacFirstName",
        f."FacLastName",
        f."FacSalary",
        ABS(f."FacSalary" - ra.avg_salary) AS diff_to_avg
    FROM "university_faculty" f
    JOIN rank_avg ra
      ON f."FacRank" = ra."FacRank"
),
min_diff_per_rank AS (
    SELECT 
        "FacRank",
        MIN(diff_to_avg) AS min_diff
    FROM faculty_diff
    GROUP BY "FacRank"
)
SELECT 
    fd."FacRank"          AS rank,
    fd."FacFirstName"     AS first_name,
    fd."FacLastName"      AS last_name,
    fd."FacSalary"        AS salary
FROM faculty_diff fd
JOIN min_diff_per_rank md
  ON fd."FacRank" = md."FacRank"
 AND fd.diff_to_avg = md.min_diff
ORDER BY 
    fd."FacRank",
    fd."FacLastName",
    fd."FacFirstName";