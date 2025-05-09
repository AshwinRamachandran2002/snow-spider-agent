WITH ENGLISH_COMPLETIONS AS (   -- all completed English course grades
    SELECT 
        ss."StudentID",
        ss."Grade"
    FROM SCHOOL_SCHEDULING.SCHOOL_SCHEDULING.STUDENT_SCHEDULES  ss
    JOIN SCHOOL_SCHEDULING.SCHOOL_SCHEDULING.CLASSES            c  ON ss."ClassID"   = c."ClassID"
    JOIN SCHOOL_SCHEDULING.SCHOOL_SCHEDULING.SUBJECTS           s  ON c."SubjectID"  = s."SubjectID"
    WHERE ss."ClassStatus" = 2          -- completed
      AND s."CategoryID"   = 'ENG'      -- English courses
), 
RANKED AS (                           -- position of every grade within the cohort
    SELECT
        ec."StudentID",
        ec."Grade",
        COUNT(*)                              OVER ()                                                 AS total_cnt,
        COUNT(*)                              OVER (ORDER BY ec."Grade" DESC
                                                   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)  AS rank_pos
    FROM ENGLISH_COMPLETIONS ec
),
QUINTILED AS (                         -- map rank position to quintile label
    SELECT
        r."StudentID",
        CASE
            WHEN (r.rank_pos * 1.0 / r.total_cnt) <= 0.20 THEN 'First'
            WHEN (r.rank_pos * 1.0 / r.total_cnt) <= 0.40 THEN 'Second'
            WHEN (r.rank_pos * 1.0 / r.total_cnt) <= 0.60 THEN 'Third'
            WHEN (r.rank_pos * 1.0 / r.total_cnt) <= 0.80 THEN 'Fourth'
            ELSE 'Fifth'
        END AS "Quintile"
    FROM RANKED r
)
SELECT
    st."StudLastName"    AS "StudentLastName",
    q."Quintile"
FROM QUINTILED q
JOIN SCHOOL_SCHEDULING.SCHOOL_SCHEDULING.STUDENTS st
      ON q."StudentID" = st."StudentID"
ORDER BY
    CASE q."Quintile"
        WHEN 'First'  THEN 1
        WHEN 'Second' THEN 2
        WHEN 'Third'  THEN 3
        WHEN 'Fourth' THEN 4
        WHEN 'Fifth'  THEN 5
    END,
    "StudentLastName" ASC NULLS LAST;