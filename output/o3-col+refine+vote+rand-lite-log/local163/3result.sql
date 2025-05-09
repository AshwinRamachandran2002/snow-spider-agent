WITH avg_rank AS (
    SELECT "FacRank",
           AVG("FacSalary") AS avg_salary
    FROM "university_faculty"
    GROUP BY "FacRank"
),
rank_diff AS (
    SELECT uf."FacRank",
           uf."FacFirstName",
           uf."FacLastName",
           uf."FacSalary",
           ABS(uf."FacSalary" - ar.avg_salary) AS diff_from_avg
    FROM "university_faculty" AS uf
    JOIN avg_rank AS ar
      ON uf."FacRank" = ar."FacRank"
),
min_diff AS (
    SELECT "FacRank",
           MIN(diff_from_avg) AS min_diff
    FROM rank_diff
    GROUP BY "FacRank"
)
SELECT rd."FacRank",
       rd."FacFirstName",
       rd."FacLastName",
       rd."FacSalary"
FROM rank_diff AS rd
JOIN min_diff  AS md
  ON rd."FacRank" = md."FacRank"
 AND rd.diff_from_avg = md.min_diff
ORDER BY rd."FacRank", rd."FacLastName", rd."FacFirstName";