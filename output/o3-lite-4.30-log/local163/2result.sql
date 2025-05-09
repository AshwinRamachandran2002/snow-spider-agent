WITH avg_rank AS (
    SELECT 
        "FacRank" AS rank,
        AVG("FacSalary") AS avg_sal
    FROM "university_faculty"
    GROUP BY "FacRank"
),
diffs AS (
    SELECT
        f."FacRank"      AS rank,
        f."FacFirstName" AS first_name,
        f."FacLastName"  AS last_name,
        printf('%.4f', f."FacSalary") AS salary,
        ABS(f."FacSalary" - a.avg_sal) AS diff_to_avg
    FROM "university_faculty" f
    JOIN avg_rank a
      ON f."FacRank" = a.rank
),
min_diff AS (
    SELECT 
        rank,
        MIN(diff_to_avg) AS min_diff
    FROM diffs
    GROUP BY rank
)
SELECT
    d.rank,
    d.first_name,
    d.last_name,
    d.salary
FROM diffs d
JOIN min_diff m
  ON d.rank = m.rank
 AND d.diff_to_avg = m.min_diff
ORDER BY 
    d.rank,
    d.last_name,
    d.first_name;