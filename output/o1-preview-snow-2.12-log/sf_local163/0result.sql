WITH avg_salary AS (
  SELECT "FacRank", AVG("FacSalary") AS "AvgSalary"
  FROM "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."UNIVERSITY_FACULTY"
  GROUP BY "FacRank"
),
faculty_diff AS (
  SELECT f."FacRank", f."FacFirstName", f."FacLastName", f."FacSalary",
  ABS(f."FacSalary" - a."AvgSalary") AS "SalaryDiff"
  FROM "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."UNIVERSITY_FACULTY" f
  JOIN avg_salary a ON f."FacRank" = a."FacRank"
),
min_diff AS (
  SELECT "FacRank", MIN("SalaryDiff") AS "MinDiff"
  FROM faculty_diff
  GROUP BY "FacRank"
)
SELECT d."FacRank" AS "Rank", d."FacFirstName" AS "FirstName", d."FacLastName" AS "LastName", ROUND(d."FacSalary", 4) AS "Salary"
FROM faculty_diff d
JOIN min_diff m ON d."FacRank" = m."FacRank" AND d."SalaryDiff" = m."MinDiff"
ORDER BY d."FacRank", d."FacLastName", d."FacFirstName";