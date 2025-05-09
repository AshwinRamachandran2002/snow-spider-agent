WITH avg_rank AS (
    SELECT "FacRank",
           AVG("FacSalary") AS avg_salary
    FROM   "university_faculty"
    GROUP BY "FacRank"
),
ranked AS (
    SELECT f."FacRank",
           f."FacFirstName",
           f."FacLastName",
           f."FacSalary",
           ROW_NUMBER() OVER (
               PARTITION BY f."FacRank"
               ORDER BY ABS(f."FacSalary" - a.avg_salary)
           ) AS rn
    FROM   "university_faculty" AS f
    JOIN   avg_rank              AS a USING ("FacRank")
)
SELECT  "FacRank",
        "FacFirstName",
        "FacLastName",
        "FacSalary"
FROM    ranked
WHERE   rn = 1
ORDER BY "FacRank", "FacLastName", "FacFirstName";