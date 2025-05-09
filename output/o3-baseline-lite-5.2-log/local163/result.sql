WITH avg_salary_per_rank AS (
    SELECT 
        "FacRank",
        AVG("FacSalary") AS avg_salary
    FROM "university_faculty"
    GROUP BY "FacRank"
),
faculty_diffs AS (
    SELECT
        uf."FacRank",
        uf."FacFirstName",
        uf."FacLastName",
        uf."FacSalary",
        ABS(uf."FacSalary" - asp.avg_salary) AS diff_to_avg,
        ROW_NUMBER() OVER (
            PARTITION BY uf."FacRank" 
            ORDER BY ABS(uf."FacSalary" - asp.avg_salary)
        ) AS rn
    FROM "university_faculty" AS uf
    JOIN avg_salary_per_rank AS asp
      ON uf."FacRank" = asp."FacRank"
)
SELECT
    "FacRank",
    "FacFirstName",
    "FacLastName",
    "FacSalary"
FROM faculty_diffs
WHERE rn = 1
ORDER BY "FacRank";