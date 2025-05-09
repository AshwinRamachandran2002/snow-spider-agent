WITH English_Completed AS (
    /* English courses that students have COMPLETED (ClassStatus = 2) */
    SELECT 
        ss.StudentID,
        ss.Grade
    FROM "Student_Schedules" AS ss
    JOIN "Classes"  AS c   ON c."ClassID"   = ss."ClassID"
    JOIN "Subjects" AS s   ON s."SubjectID" = c."SubjectID"
    WHERE ss."ClassStatus" = 2          -- completed
      AND s."CategoryID"   = 'ENG'      -- English courses
),
Ranked AS (
    /* Position each grade from highest to lowest, count total rows  */
    SELECT
        ec.StudentID,
        ec.Grade,
        ROW_NUMBER() OVER (ORDER BY ec.Grade DESC) AS pos,      -- # of grades ≥ current grade
        COUNT(*)  OVER ()                                       AS total
    FROM English_Completed ec
),
Quintile_Map AS (
    /* Convert the position into a quintile label */
    SELECT
        r.StudentID,
        CASE
            WHEN 1.0 * r.pos / r.total <= 0.20 THEN 'First'
            WHEN 1.0 * r.pos / r.total <= 0.40 THEN 'Second'
            WHEN 1.0 * r.pos / r.total <= 0.60 THEN 'Third'
            WHEN 1.0 * r.pos / r.total <= 0.80 THEN 'Fourth'
            ELSE 'Fifth'
        END AS Quintile
    FROM Ranked r
)
SELECT 
    st."StudLastName" AS "LastName",
    q.Quintile
FROM Quintile_Map q
JOIN "Students" st ON st."StudentID" = q."StudentID"
ORDER BY 
    CASE q.Quintile
        WHEN 'First'  THEN 1
        WHEN 'Second' THEN 2
        WHEN 'Third'  THEN 3
        WHEN 'Fourth' THEN 4
        WHEN 'Fifth'  THEN 5
    END,
    st."StudLastName";