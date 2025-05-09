WITH rank_avg AS (     -- average salary per rank
    SELECT 
        "FacRank",
        AVG("FacSalary") AS "avg_salary"
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS.UNIVERSITY_FACULTY
    GROUP BY "FacRank"
),
rank_diff AS (         -- distance of each faculty salary from its rank average
    SELECT
        f."FacRank",
        f."FacFirstName",
        f."FacLastName",
        f."FacSalary",
        ABS(f."FacSalary" - ra."avg_salary") AS "salary_diff",
        ROW_NUMBER() OVER (
            PARTITION BY f."FacRank"
            ORDER BY ABS(f."FacSalary" - ra."avg_salary")
        ) AS "rn"
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS.UNIVERSITY_FACULTY f
    JOIN rank_avg ra
      ON f."FacRank" = ra."FacRank"
)
SELECT
    "FacRank",
    "FacFirstName",
    "FacLastName",
    "FacSalary"
FROM rank_diff
WHERE "rn" = 1              -- closest to average in each rank
ORDER BY "FacRank";