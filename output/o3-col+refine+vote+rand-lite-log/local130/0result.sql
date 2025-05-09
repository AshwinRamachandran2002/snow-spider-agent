WITH english_completed AS (
    SELECT st."StudLastName" AS "LastName",
           ss."Grade"
    FROM "Student_Schedules" AS ss
    JOIN "Classes"   AS c  ON ss."ClassID"  = c."ClassID"
    JOIN "Subjects"  AS s  ON c."SubjectID" = s."SubjectID"
    JOIN "Students"  AS st ON ss."StudentID" = st."StudentID"
    WHERE ss."ClassStatus" = 2           -- completed classes
      AND s."CategoryID"   = 'ENG'       -- English courses
),
ranked AS (
    SELECT ec."LastName",
           ec."Grade",
           (SELECT COUNT(*) FROM english_completed ec2
             WHERE ec2."Grade" >= ec."Grade") AS "Position",
           (SELECT COUNT(*) FROM english_completed)            AS "Total"
    FROM english_completed ec
),
labeled AS (
    SELECT "LastName",
           CASE
               WHEN 1.0 * "Position" / "Total" <= 0.20 THEN 'First'
               WHEN 1.0 * "Position" / "Total" <= 0.40 THEN 'Second'
               WHEN 1.0 * "Position" / "Total" <= 0.60 THEN 'Third'
               WHEN 1.0 * "Position" / "Total" <= 0.80 THEN 'Fourth'
               ELSE 'Fifth'
           END AS "Quintile"
    FROM ranked
)
SELECT DISTINCT "LastName", "Quintile"
FROM labeled
ORDER BY
    CASE "Quintile"
        WHEN 'First'  THEN 1
        WHEN 'Second' THEN 2
        WHEN 'Third'  THEN 3
        WHEN 'Fourth' THEN 4
        ELSE 5
    END;