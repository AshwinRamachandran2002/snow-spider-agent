SELECT f."FacRank" AS "Rank",
       f."FacFirstName" AS "FirstName",
       f."FacLastName" AS "LastName",
       ROUND(f."FacSalary", 4) AS "Salary"
FROM "university_faculty" f
JOIN (
  SELECT "FacRank",
         AVG("FacSalary") AS "AverageSalary"
  FROM "university_faculty"
  GROUP BY "FacRank"
) avg_salaries ON f."FacRank" = avg_salaries."FacRank"
JOIN (
  SELECT "FacRank",
         MIN(ROUND(ABS("FacSalary" - "AverageSalary"), 4)) AS "MinSalaryDifference"
  FROM (
    SELECT f2."FacRank",
           f2."FacSalary",
           avg_salaries2."AverageSalary"
    FROM "university_faculty" f2
    JOIN (
      SELECT "FacRank",
             AVG("FacSalary") AS "AverageSalary"
          FROM "university_faculty"
          GROUP BY "FacRank"
      ) avg_salaries2 ON f2."FacRank" = avg_salaries2."FacRank"
    )
  GROUP BY "FacRank"
) min_diff ON f."FacRank" = min_diff."FacRank"
WHERE ROUND(ABS(f."FacSalary" - avg_salaries."AverageSalary"), 4) = min_diff."MinSalaryDifference"
ORDER BY f."FacRank";