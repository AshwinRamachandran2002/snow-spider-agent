WITH rank_avg AS (
    SELECT 
        "FacRank",
        AVG("FacSalary") AS avg_salary
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS."UNIVERSITY_FACULTY"
    GROUP BY "FacRank"
),
rank_diff AS (
    SELECT 
        f."FacRank",
        f."FacFirstName",
        f."FacLastName",
        f."FacSalary",
        ABS(f."FacSalary" - ra.avg_salary) AS diff_to_avg
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS."UNIVERSITY_FACULTY" f
    JOIN rank_avg ra
      ON f."FacRank" = ra."FacRank"
),
min_diff AS (
    SELECT 
        "FacRank",
        MIN(diff_to_avg) AS min_diff_to_avg
    FROM rank_diff
    GROUP BY "FacRank"
)
SELECT 
    rd."FacRank",
    rd."FacFirstName",
    rd."FacLastName",
    rd."FacSalary"
FROM rank_diff rd
JOIN min_diff md
  ON rd."FacRank" = md."FacRank"
 AND rd.diff_to_avg = md.min_diff_to_avg
ORDER BY 
    rd."FacRank",
    rd."FacLastName",
    rd."FacFirstName";