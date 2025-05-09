WITH english_completions AS (             -- every completed English class/grade
    SELECT
        ss."StudentID",
        ss."Grade"
    FROM "Student_Schedules"  ss
    JOIN "Classes"            cl ON cl."ClassID"   = ss."ClassID"
    JOIN "Subjects"           sb ON sb."SubjectID" = cl."SubjectID"
    WHERE ss."ClassStatus" = 2          -- completed
      AND sb."CategoryID"   = 'ENG'     -- English courses
),
ranked AS (                              -- put all grades into 5 equal‑sized buckets
    SELECT
        ec."StudentID",
        NTILE(5) OVER (ORDER BY ec."Grade" DESC) AS "QNum"
    FROM english_completions ec
),
labeled AS (                             -- translate bucket numbers into labels
    SELECT
        st."StudLastName" AS "LastName",
        CASE "QNum"
             WHEN 1 THEN 'First'
             WHEN 2 THEN 'Second'
             WHEN 3 THEN 'Third'
             WHEN 4 THEN 'Fourth'
             WHEN 5 THEN 'Fifth'
        END AS "Quintile"
    FROM ranked r
    JOIN "Students" st ON st."StudentID" = r."StudentID"
)
SELECT DISTINCT
       "LastName",
       "Quintile"
FROM   labeled
ORDER BY
    CASE "Quintile"
         WHEN 'First'  THEN 1
         WHEN 'Second' THEN 2
         WHEN 'Third'  THEN 3
         WHEN 'Fourth' THEN 4
         WHEN 'Fifth'  THEN 5
    END,
    "LastName";