WITH avg_salaries AS (
    SELECT "FacRank", ROUND(AVG("FacSalary"), 4) AS "AvgSalary"
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS.UNIVERSITY_FACULTY
    GROUP BY "FacRank"
),
diff_salaries AS (
    SELECT
        uf."FacRank" AS "Rank",
        uf."FacFirstName" AS "FirstName",
        uf."FacLastName" AS "LastName",
        TO_DECIMAL(uf."FacSalary", 10, 4) AS "Salary",
        ROUND(ABS(uf."FacSalary" - avg."AvgSalary"), 4) AS "SalaryDiff"
    FROM
        EDUCATION_BUSINESS.EDUCATION_BUSINESS.UNIVERSITY_FACULTY uf
        JOIN avg_salaries avg ON uf."FacRank" = avg."FacRank"
),
min_diffs AS (
    SELECT "Rank", MIN("SalaryDiff") AS "MinDiff"
    FROM diff_salaries
    GROUP BY "Rank"
)
SELECT
    d."Rank",
    d."FirstName",
    d."LastName",
    d."Salary"
FROM
    diff_salaries d
    JOIN min_diffs m ON d."Rank" = m."Rank" AND d."SalaryDiff" = m."MinDiff"
ORDER BY
    d."Rank";