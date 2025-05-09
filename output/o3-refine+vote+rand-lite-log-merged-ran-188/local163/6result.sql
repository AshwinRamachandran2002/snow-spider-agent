WITH rank_avg AS (
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
        ABS(f."FacSalary" - ra.avg_salary) AS diff,
        MIN(ABS(f."FacSalary" - ra.avg_salary)) OVER (PARTITION BY f."FacRank") AS min_diff
    FROM "university_faculty" AS f
    JOIN rank_avg AS ra
      ON f."FacRank" = ra."FacRank"
)
SELECT
    "FacRank"      AS rank,
    "FacFirstName" AS first_name,
    "FacLastName"  AS last_name,
    "FacSalary"    AS salary
FROM rank_diff
WHERE diff = min_diff
ORDER BY rank,
         last_name,
         first_name;