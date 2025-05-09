WITH Completed_English AS (
    SELECT ss."StudentID",
           ss."Grade"
    FROM "Student_Schedules" AS ss
    JOIN "Classes"  AS c   ON c."ClassID"    = ss."ClassID"
    JOIN "Subjects" AS sub ON sub."SubjectID" = c."SubjectID"
    WHERE ss."ClassStatus" = 2                -- completed courses
      AND sub."CategoryID"  = 'ENG'           -- English courses
),
Best_Grade AS (                               -- one grade per student
    SELECT ce."StudentID",
           MAX(ce."Grade") AS "Best_Grade"    -- use highest English grade
    FROM Completed_English AS ce
    GROUP BY ce."StudentID"
),
Ranked AS (
    SELECT bg.*,
           NTILE(5) OVER (ORDER BY bg."Best_Grade" DESC) AS "q_num"
    FROM Best_Grade AS bg
),
Labelled AS (
    SELECT r."StudentID",
           CASE r."q_num"
                WHEN 1 THEN 'First'
                WHEN 2 THEN 'Second'
                WHEN 3 THEN 'Third'
                WHEN 4 THEN 'Fourth'
                ELSE 'Fifth'
           END AS "Quintile"
    FROM Ranked AS r
)
SELECT s."StudLastName" AS "LastName",
       l."Quintile"
FROM Labelled AS l
JOIN "Students" AS s ON s."StudentID" = l."StudentID"
ORDER BY CASE l."Quintile"
             WHEN 'First'  THEN 1
             WHEN 'Second' THEN 2
             WHEN 'Third'  THEN 3
             WHEN 'Fourth' THEN 4
             ELSE 5
         END,
         s."StudLastName";