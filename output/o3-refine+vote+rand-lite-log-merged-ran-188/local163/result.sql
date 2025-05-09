WITH avg_per_rank AS (
    SELECT 
        "FacRank",
        AVG("FacSalary") AS avg_salary
    FROM "university_faculty"
    GROUP BY "FacRank"
),
rank_diff AS (
    SELECT
        f."FacRank",
        f."FacFirstName",
        f."FacLastName",
        f."FacSalary",
        ABS(f."FacSalary" - a.avg_salary) AS diff_from_avg
    FROM "university_faculty" f
    JOIN avg_per_rank a
      ON f."FacRank" = a."FacRank"
)
SELECT
    "FacRank"  AS rank,
    "FacFirstName" AS first_name,
    "FacLastName"  AS last_name,
    "FacSalary"    AS salary
FROM rank_diff
WHERE diff_from_avg = (
        SELECT MIN(rd2.diff_from_avg)
        FROM rank_diff rd2
        WHERE rd2."FacRank" = rank_diff."FacRank"
)
ORDER BY
    rank,
    last_name,
    first_name;