WITH avg_rank AS (
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
        ABS(f."FacSalary" - a.avg_salary) AS diff_to_avg
    FROM "university_faculty" AS f
    JOIN avg_rank AS a
      ON f."FacRank" = a."FacRank"
),
min_diff AS (
    SELECT
        "FacRank",
        MIN(diff_to_avg) AS min_diff
    FROM rank_diff
    GROUP BY "FacRank"
)
SELECT
    rd."FacRank"  AS rank,
    rd."FacFirstName" AS first_name,
    rd."FacLastName"  AS last_name,
    rd."FacSalary"    AS salary
FROM rank_diff AS rd
JOIN min_diff  AS md
  ON rd."FacRank" = md."FacRank"
 AND rd.diff_to_avg = md.min_diff
ORDER BY
    rd."FacRank",
    rd."FacLastName",
    rd."FacFirstName";