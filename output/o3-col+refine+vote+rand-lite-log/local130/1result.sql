WITH BestEnglishGrade AS (
    SELECT
        ss."StudentID",
        MAX(ss."Grade") AS Grade
    FROM "Student_Schedules" ss
    JOIN "Classes"   c  ON c."ClassID"   = ss."ClassID"
    JOIN "Subjects"  su ON su."SubjectID" = c."SubjectID"
    WHERE ss."ClassStatus" = 2           -- completed
      AND su."CategoryID"  = 'ENG'       -- English courses
    GROUP BY ss."StudentID"
),
Ranked AS (
    SELECT
        beg."StudentID",
        beg."Grade",
        CUME_DIST() OVER (ORDER BY beg."Grade" DESC) AS cd
    FROM BestEnglishGrade beg
)
SELECT
    st."StudLastName" AS "LastName",
    CASE
        WHEN r.cd <= 0.20 THEN 'First'
        WHEN r.cd <= 0.40 THEN 'Second'
        WHEN r.cd <= 0.60 THEN 'Third'
        WHEN r.cd <= 0.80 THEN 'Fourth'
        ELSE 'Fifth'
    END AS "Quintile"
FROM Ranked r
JOIN "Students" st ON st."StudentID" = r."StudentID"
ORDER BY
    CASE
        WHEN r.cd <= 0.20 THEN 1
        WHEN r.cd <= 0.40 THEN 2
        WHEN r.cd <= 0.60 THEN 3
        WHEN r.cd <= 0.80 THEN 4
        ELSE 5
    END,
    "LastName";