SELECT sub."FacRank" AS "Rank", sub."FacFirstName" AS "FirstName", sub."FacLastName" AS "LastName", ROUND(sub."FacSalary", 4) AS "Salary"
FROM (
    SELECT
        f."FacRank",
        f."FacFirstName",
        f."FacLastName",
        f."FacSalary",
        ABS(f."FacSalary" - AVG_FR."AverageSalary") AS "SalaryDifference",
        DENSE_RANK() OVER(PARTITION BY f."FacRank" ORDER BY ABS(f."FacSalary" - AVG_FR."AverageSalary")) AS "SalaryRank"
    FROM
        "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."UNIVERSITY_FACULTY" f
    JOIN
        (
            SELECT "FacRank", AVG("FacSalary") AS "AverageSalary"
            FROM "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."UNIVERSITY_FACULTY"
            GROUP BY "FacRank"
        ) AVG_FR
    ON f."FacRank" = AVG_FR."FacRank"
) sub
WHERE sub."SalaryRank" = 1
ORDER BY sub."FacRank" ASC;