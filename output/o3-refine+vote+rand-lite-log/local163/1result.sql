WITH avg_per_rank AS (
    SELECT 
        "FacRank",
        AVG("FacSalary") AS avg_salary
    FROM "university_faculty"
    GROUP BY "FacRank"
),
salary_diff AS (
    SELECT 
        uf."FacRank",
        uf."FacFirstName",
        uf."FacLastName",
        uf."FacSalary",
        ABS(uf."FacSalary" - apr.avg_salary) AS diff_to_avg
    FROM "university_faculty" uf
    JOIN avg_per_rank apr
      ON uf."FacRank" = apr."FacRank"
),
min_diff AS (
    SELECT 
        "FacRank",
        MIN(diff_to_avg) AS min_diff
    FROM salary_diff
    GROUP BY "FacRank"
)
SELECT 
    sd."FacRank",
    sd."FacFirstName",
    sd."FacLastName",
    sd."FacSalary"
FROM salary_diff sd
JOIN min_diff md
  ON sd."FacRank" = md."FacRank"
 AND sd.diff_to_avg = md.min_diff
ORDER BY 
    sd."FacRank",
    sd."FacLastName",
    sd."FacFirstName";