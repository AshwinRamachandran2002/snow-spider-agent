WITH rank_avg AS (
    SELECT "FacRank", AVG("FacSalary") AS avg_salary
    FROM "university_faculty"
    GROUP BY "FacRank"
),
rank_min_diff AS (
    SELECT f."FacRank",
           MIN(ABS(f."FacSalary" - ra.avg_salary)) AS min_diff
    FROM "university_faculty" f
    JOIN rank_avg ra ON f."FacRank" = ra."FacRank"
    GROUP BY f."FacRank"
)
SELECT
    f."FacRank"           AS rank,
    f."FacFirstName"      AS first_name,
    f."FacLastName"       AS last_name,
    printf('%.4f', f."FacSalary") AS salary
FROM "university_faculty" f
JOIN rank_avg      ra ON f."FacRank" = ra."FacRank"
JOIN rank_min_diff md ON f."FacRank" = md."FacRank"
WHERE ABS(f."FacSalary" - ra.avg_salary) = md.min_diff
ORDER BY rank, last_name, first_name;