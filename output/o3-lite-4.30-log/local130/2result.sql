WITH ranked AS (
    SELECT
        st."StudLastName" AS "LastName",
        ss."Grade",
        RANK()  OVER (ORDER BY ss."Grade" DESC) AS "rk",
        COUNT(*) OVER ()                       AS "total"
    FROM "Student_Schedules" AS ss
    JOIN "Classes"  AS c  ON c."ClassID"   = ss."ClassID"
    JOIN "Subjects" AS s  ON s."SubjectID" = c."SubjectID"
    JOIN "Students" AS st ON st."StudentID"= ss."StudentID"
    WHERE ss."ClassStatus" = 2
      AND s."CategoryID"   = 'ENG'
)
SELECT
    "LastName",
    CASE
        WHEN 1.0 * "rk" / "total" <= 0.20 THEN 'First'
        WHEN 1.0 * "rk" / "total" <= 0.40 THEN 'Second'
        WHEN 1.0 * "rk" / "total" <= 0.60 THEN 'Third'
        WHEN 1.0 * "rk" / "total" <= 0.80 THEN 'Fourth'
        ELSE 'Fifth'
    END AS "Quintile"
FROM ranked
ORDER BY
    CASE
        WHEN 1.0 * "rk" / "total" <= 0.20 THEN 1
        WHEN 1.0 * "rk" / "total" <= 0.40 THEN 2
        WHEN 1.0 * "rk" / "total" <= 0.60 THEN 3
        WHEN 1.0 * "rk" / "total" <= 0.80 THEN 4
        ELSE 5
    END,
    "Grade" DESC,
    "LastName";