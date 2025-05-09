WITH english_classes AS (
    SELECT c."ClassID"
    FROM "Classes"   AS c
    JOIN "Subjects"  AS s ON s."SubjectID" = c."SubjectID"
    WHERE s."CategoryID" = 'ENG'
),
-- Best (highest) English grade per student who completed the course(s)
eng_best AS (
    SELECT ss."StudentID",
           MAX(ss."Grade") AS "Grade"
    FROM "Student_Schedules" AS ss
    WHERE ss."ClassStatus" = 2
      AND ss."ClassID" IN (SELECT "ClassID" FROM english_classes)
    GROUP BY ss."StudentID"
),
-- Determine cumulative position (how many students have grade ≥ current)
ranked AS (
    SELECT eb."StudentID",
           CUME_DIST() OVER (ORDER BY eb."Grade" DESC) AS cd
    FROM eng_best eb
),
-- Map cumulative position to quintile labels
quintiled AS (
    SELECT r."StudentID",
           CASE
               WHEN r.cd <= 0.20 THEN 'First'
               WHEN r.cd <= 0.40 THEN 'Second'
               WHEN r.cd <= 0.60 THEN 'Third'
               WHEN r.cd <= 0.80 THEN 'Fourth'
               ELSE 'Fifth'
           END AS "Quintile"
    FROM ranked r
)
SELECT st."StudLastName",
       q."Quintile"
FROM   quintiled AS q
JOIN   "Students" AS st ON st."StudentID" = q."StudentID"
ORDER BY CASE q."Quintile"
             WHEN 'First'  THEN 1
             WHEN 'Second' THEN 2
             WHEN 'Third'  THEN 3
             WHEN 'Fourth' THEN 4
             ELSE 5
         END,
         st."StudLastName";