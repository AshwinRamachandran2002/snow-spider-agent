WITH avg_salary_per_rank AS (
    SELECT
        "FacRank",
        AVG("FacSalary") AS avg_salary
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS.UNIVERSITY_FACULTY
    WHERE "FacSalary" IS NOT NULL
    GROUP BY "FacRank"
),
ranked_faculty AS (
    SELECT
        f."FacRank",
        f."FacFirstName",
        f."FacLastName",
        f."FacSalary",
        ABS(f."FacSalary" - a.avg_salary) AS salary_diff,
        ROW_NUMBER() OVER (
            PARTITION BY f."FacRank"
            ORDER BY ABS(f."FacSalary" - a.avg_salary), f."FacSalary"
        ) AS rn
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS.UNIVERSITY_FACULTY f
    JOIN avg_salary_per_rank a
      ON f."FacRank" = a."FacRank"
    WHERE f."FacSalary" IS NOT NULL
)
SELECT
    "FacRank"        AS "rank",
    "FacFirstName",
    "FacLastName",
    "FacSalary"
FROM ranked_faculty
WHERE rn = 1
ORDER BY "rank";