/*  List every (completed) English-course grade, attach a quintile label,
    and return students’ last names with those labels ordered
    from highest-performing quintile (“First”) to lowest (“Fifth”). */
WITH english_grades AS (
    SELECT  s."StudLastName",
            ss."Grade"
    FROM    "Student_Schedules"  AS ss
    JOIN    "Classes"            AS c   ON c."ClassID"   = ss."ClassID"
    JOIN    "Subjects"           AS sub ON sub."SubjectID" = c."SubjectID"
    JOIN    "Students"           AS s   ON s."StudentID" = ss."StudentID"
    WHERE   ss."ClassStatus" = 2        -- completed
      AND   sub."CategoryID"  = 'ENG'   -- English courses
), ranked AS (
    SELECT  eg."StudLastName",
            eg."Grade",
            RANK() OVER (ORDER BY eg."Grade" DESC)        AS rnk,
            COUNT(*) OVER ()                              AS cnt
    FROM    english_grades AS eg
)
SELECT  r."StudLastName",
        CASE
             WHEN ( (r.rnk - 1) * 1.0 / r.cnt ) < 0.20 THEN 'First'
             WHEN ( (r.rnk - 1) * 1.0 / r.cnt ) < 0.40 THEN 'Second'
             WHEN ( (r.rnk - 1) * 1.0 / r.cnt ) < 0.60 THEN 'Third'
             WHEN ( (r.rnk - 1) * 1.0 / r.cnt ) < 0.80 THEN 'Fourth'
             ELSE 'Fifth'
        END AS "Quintile"
FROM    ranked AS r
ORDER BY CASE
             WHEN ( (r.rnk - 1) * 1.0 / r.cnt ) < 0.20 THEN 1
             WHEN ( (r.rnk - 1) * 1.0 / r.cnt ) < 0.40 THEN 2
             WHEN ( (r.rnk - 1) * 1.0 / r.cnt ) < 0.60 THEN 3
             WHEN ( (r.rnk - 1) * 1.0 / r.cnt ) < 0.80 THEN 4
             ELSE 5
         END,
         r."StudLastName";