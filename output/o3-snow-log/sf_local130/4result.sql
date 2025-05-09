WITH english_subjects AS (
    SELECT s."SubjectID"
    FROM SCHOOL_SCHEDULING.SCHOOL_SCHEDULING.SUBJECTS      s
    JOIN SCHOOL_SCHEDULING.SCHOOL_SCHEDULING.CATEGORIES    c
          ON s."CategoryID" = c."CategoryID"
    WHERE LOWER(c."CategoryDescription") = 'english'
), english_completions AS (
    SELECT ss."StudentID",
           ss."Grade"
    FROM SCHOOL_SCHEDULING.SCHOOL_SCHEDULING.STUDENT_SCHEDULES ss
    JOIN SCHOOL_SCHEDULING.SCHOOL_SCHEDULING.CLASSES          cl
          ON ss."ClassID" = cl."ClassID"
    WHERE ss."ClassStatus" = 2                          -- completed
      AND cl."SubjectID" IN (SELECT "SubjectID" FROM english_subjects)
), student_avg AS (                                     -- average English grade per student
    SELECT ec."StudentID",
           AVG(ec."Grade") AS avg_grade
    FROM english_completions ec
    GROUP BY ec."StudentID"
), ranked AS (                                          -- position of each student
    SELECT sa.*,
           COUNT(*) OVER (ORDER BY sa.avg_grade DESC
                          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS rnk,
           COUNT(*) OVER () AS total_students
    FROM student_avg sa
), quintiled AS (
    SELECT r."StudentID",
           CEIL(r.rnk * 5.0 / r.total_students) AS quintile_num
    FROM ranked r
)
SELECT st."StudLastName" AS "LastName",
       CASE quintile_num
            WHEN 1 THEN 'First'
            WHEN 2 THEN 'Second'
            WHEN 3 THEN 'Third'
            WHEN 4 THEN 'Fourth'
            ELSE 'Fifth'
       END AS "Quintile"
FROM quintiled q
JOIN SCHOOL_SCHEDULING.SCHOOL_SCHEDULING.STUDENTS st
     ON q."StudentID" = st."StudentID"
ORDER BY quintile_num ASC;     -- First (top 20%) down to Fifth (bottom 20%)