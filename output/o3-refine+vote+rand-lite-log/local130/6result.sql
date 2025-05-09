WITH EnglishCompletions AS (
    /* 1.  All completed English classes with each student's grade */
    SELECT
        ss.StudentID,
        st."StudLastName"  AS LastName,
        ss.Grade
    FROM "Student_Schedules" AS ss
    JOIN "Classes"          AS c   ON c."ClassID"  = ss."ClassID"
    JOIN "Subjects"         AS su  ON su."SubjectID" = c."SubjectID"
    JOIN "Students"         AS st  ON st."StudentID" = ss."StudentID"
    WHERE ss."ClassStatus" = 2          -- completed
      AND su."CategoryID"  = 'ENG'      -- English subjects
),
Ranked AS (
    /* 2.  Position of each grade (1 = highest) and total count */
    SELECT
        ec.LastName,
        ec.Grade,
        ( SELECT COUNT(*) FROM EnglishCompletions  )                              AS total_cnt,
        ( SELECT COUNT(*) FROM EnglishCompletions 
          WHERE Grade >= ec.Grade )                                               AS rank_pos
    FROM EnglishCompletions ec
),
Quintiled AS (
    /* 3.  Translate the percentile position into a quintile label */
    SELECT
        LastName,
        CASE
            WHEN 1.0*rank_pos/total_cnt <= 0.20 THEN 'First'
            WHEN 1.0*rank_pos/total_cnt <= 0.40 THEN 'Second'
            WHEN 1.0*rank_pos/total_cnt <= 0.60 THEN 'Third'
            WHEN 1.0*rank_pos/total_cnt <= 0.80 THEN 'Fourth'
            ELSE                                   'Fifth'
        END AS Quintile
    FROM Ranked
)
SELECT DISTINCT
       LastName,
       Quintile
FROM Quintiled
ORDER BY
    CASE Quintile
        WHEN 'First'  THEN 1
        WHEN 'Second' THEN 2
        WHEN 'Third'  THEN 3
        WHEN 'Fourth' THEN 4
        WHEN 'Fifth'  THEN 5
    END;