WITH english_subjects AS (   -- all English subject IDs
    SELECT  s."SubjectID"
    FROM    SCHOOL_SCHEDULING.SCHOOL_SCHEDULING.SUBJECTS   s
    JOIN    SCHOOL_SCHEDULING.SCHOOL_SCHEDULING.CATEGORIES c
           ON s."CategoryID" = c."CategoryID"
    WHERE   c."CategoryDescription" = 'English'
),
english_grades AS (         -- grades earned in completed English classes
    SELECT  ss."StudentID",
            ss."Grade"
    FROM    SCHOOL_SCHEDULING.SCHOOL_SCHEDULING.STUDENT_SCHEDULES ss
    JOIN    SCHOOL_SCHEDULING.SCHOOL_SCHEDULING.CLASSES          cl
           ON ss."ClassID" = cl."ClassID"
    WHERE   ss."ClassStatus" = 2          -- completed classes
      AND   cl."SubjectID" IN (SELECT "SubjectID" FROM english_subjects)
),
student_avg AS (            -- one average English grade per student
    SELECT  "StudentID",
            AVG("Grade")  AS avg_grade
    FROM    english_grades
    GROUP BY "StudentID"
),
ranked AS (                  -- cumulative-distribution to build quintiles
    SELECT  sa."StudentID",
            sa.avg_grade,
            CUME_DIST() OVER (ORDER BY sa.avg_grade DESC) AS cum_pct
    FROM    student_avg sa
)
SELECT  st."StudLastName"                   AS "LastName",
        CASE
             WHEN r.cum_pct <= 0.20 THEN 'First'
             WHEN r.cum_pct <= 0.40 THEN 'Second'
             WHEN r.cum_pct <= 0.60 THEN 'Third'
             WHEN r.cum_pct <= 0.80 THEN 'Fourth'
             ELSE                         'Fifth'
        END                                AS "Quintile"
FROM    ranked  r
JOIN    SCHOOL_SCHEDULING.SCHOOL_SCHEDULING.STUDENTS st
       ON r."StudentID" = st."StudentID"
ORDER BY
        CASE                               -- First → Fifth
             WHEN r.cum_pct <= 0.20 THEN 1
             WHEN r.cum_pct <= 0.40 THEN 2
             WHEN r.cum_pct <= 0.60 THEN 3
             WHEN r.cum_pct <= 0.80 THEN 4
             ELSE                         5
        END,
        st."StudLastName";