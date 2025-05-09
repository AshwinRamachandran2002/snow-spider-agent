WITH rank_avg AS (
    SELECT
        "FacRank",
        AVG("FacSalary") AS "AvgSalary"
    FROM "university_faculty"
    GROUP BY "FacRank"
),
rank_diff AS (
    SELECT
        f."FacRank",
        f."FacFirstName",
        f."FacLastName",
        f."FacSalary",
        ABS(f."FacSalary" - ra."AvgSalary") AS "DiffToAvg"
    FROM "university_faculty" AS f
    JOIN rank_avg AS ra
      ON f."FacRank" = ra."FacRank"
),
min_diff AS (
    SELECT
        "FacRank",
        MIN("DiffToAvg") AS "MinDiff"
    FROM rank_diff
    GROUP BY "FacRank"
)
SELECT
    rd."FacRank",
    rd."FacFirstName",
    rd."FacLastName",
    rd."FacSalary"
FROM rank_diff AS rd
JOIN min_diff AS md
  ON rd."FacRank" = md."FacRank"
 AND rd."DiffToAvg" = md."MinDiff"
ORDER BY rd."FacRank",
         rd."FacLastName",
         rd."FacFirstName";