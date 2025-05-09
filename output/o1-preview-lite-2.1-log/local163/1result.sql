SELECT uf."FacRank" AS Rank, uf."FacFirstName" AS FirstName, uf."FacLastName" AS LastName, uf."FacSalary" AS Salary
FROM "university_faculty" uf
JOIN (
    SELECT "FacRank", AVG("FacSalary") AS "AvgSalary"
    FROM "university_faculty"
    GROUP BY "FacRank"
) avg_salaries ON uf."FacRank" = avg_salaries."FacRank"
WHERE ABS(uf."FacSalary" - avg_salaries."AvgSalary") = (
    SELECT MIN(ABS(uf2."FacSalary" - avg_salaries."AvgSalary"))
    FROM "university_faculty" uf2
    WHERE uf2."FacRank" = uf."FacRank"
)
ORDER BY uf."FacRank";