WITH AvgSalaries AS (
    SELECT "FacRank", ROUND(AVG("FacSalary"), 4) AS "AvgSalary"
    FROM "university_faculty"
    GROUP BY "FacRank"
),
SalaryDifferences AS (
    SELECT 
        u."FacRank" AS "Rank",
        u."FacFirstName" AS "FirstName",
        u."FacLastName" AS "LastName",
        u."FacSalary" AS "Salary",
        ROUND(ABS(u."FacSalary" - a."AvgSalary"), 4) AS "SalaryDifference"
    FROM "university_faculty" u
    JOIN AvgSalaries a ON u."FacRank" = a."FacRank"
),
MinDifferences AS (
    SELECT "Rank", MIN("SalaryDifference") AS "MinSalaryDifference"
    FROM SalaryDifferences
    GROUP BY "Rank"
)
SELECT s."Rank", s."FirstName", s."LastName", s."Salary"
FROM SalaryDifferences s
JOIN MinDifferences m ON s."Rank" = m."Rank" AND s."SalaryDifference" = m."MinSalaryDifference";