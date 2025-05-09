WITH english_completed AS (
    /* English courses that students have COMPLETED (ClassStatus = 2)   */
    SELECT 
        ss.StudentID,
        ss.Grade
    FROM "Student_Schedules" ss
    JOIN "Classes"   c   ON ss."ClassID"   = c."ClassID"
    JOIN "Subjects"  s   ON c."SubjectID"  = s."SubjectID"
    JOIN "Categories" cat ON s."CategoryID" = cat."CategoryID"
    WHERE ss."ClassStatus" = 2
          -- English = CategoryID 'ENG' (or CategoryDescription = 'English')
          AND cat."CategoryDescription" = 'English'
),
ranked AS (
    /* Rank each completed‑course grade (ties receive the same rank)   */
    SELECT
        ec.StudentID,
        ec.Grade,
        RANK()  OVER (ORDER BY ec.Grade DESC) AS rnk,
        COUNT(*) OVER ()                      AS total_cnt
    FROM english_completed ec
),
quintiled AS (
    /* Turn rank position into a quintile label                       */
    SELECT
        r.StudentID,
        CASE
            WHEN 1.0 * r.rnk / r.total_cnt <= 0.20 THEN 'First'
            WHEN 1.0 * r.rnk / r.total_cnt <= 0.40 THEN 'Second'
            WHEN 1.0 * r.rnk / r.total_cnt <= 0.60 THEN 'Third'
            WHEN 1.0 * r.rnk / r.total_cnt <= 0.80 THEN 'Fourth'
            ELSE                                         'Fifth'
        END AS Quintile
    FROM ranked r
)
SELECT
    st."StudLastName" AS "LastName",
    q."Quintile"
FROM quintiled q
JOIN "Students" st ON st."StudentID" = q."StudentID"
ORDER BY
    CASE q."Quintile"
        WHEN 'First'  THEN 1
        WHEN 'Second' THEN 2
        WHEN 'Third'  THEN 3
        WHEN 'Fourth' THEN 4
        ELSE              5
    END,
    st."StudLastName";