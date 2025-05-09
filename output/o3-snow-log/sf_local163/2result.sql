WITH rank_avg AS (
    SELECT
        "FacRank",
        AVG("FacSalary") AS avg_salary
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS.UNIVERSITY_FACULTY
    WHERE "FacSalary" IS NOT NULL
    GROUP BY "FacRank"
),
faculty_diff AS (
    SELECT
        f."FacRank",
        f."FacFirstName",
        f."FacLastName",
        f."FacSalary",
        ABS(f."FacSalary" - ra.avg_salary) AS salary_diff
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS.UNIVERSITY_FACULTY f
    JOIN rank_avg ra
      ON f."FacRank" = ra."FacRank"
)
SELECT
    "FacRank",
    "FacFirstName",
    "FacLastName",
    "FacSalary"
FROM faculty_diff
QUALIFY salary_diff = MIN(salary_diff) OVER (PARTITION BY "FacRank")
ORDER BY "FacRank", "FacLastName", "FacFirstName";