-- Task: For each university faculty member, calculate the absolute difference between their salary and the average salary for their rank. Provide their rank, first name, last name, salary, and the salary difference.

SELECT
    f."FacRank" AS "Rank",
    f."FacFirstName" AS "FirstName",
    f."FacLastName" AS "LastName",
    ROUND(f."FacSalary", 4) AS "Salary",
    ABS(f."FacSalary" - AVG_FR."AverageSalary") AS "SalaryDifference"
FROM
    "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."UNIVERSITY_FACULTY" f
JOIN
    (
        SELECT "FacRank", AVG("FacSalary") AS "AverageSalary"
        FROM "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."UNIVERSITY_FACULTY"
        GROUP BY "FacRank"
    ) AVG_FR
ON f."FacRank" = AVG_FR."FacRank";