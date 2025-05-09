WITH english_completers AS (
    /* one record per student who has COMPLETED (ClassStatus = 2) any English class */
    SELECT  s."StudentID",
            s."StudLastName"      AS "LastName",
            MAX(ss."Grade")       AS "Grade"      -- best grade if several English completions
    FROM   "Student_Schedules"  ss
    JOIN   "Classes"            c   ON c."ClassID"   = ss."ClassID"
    JOIN   "Subjects"           sub ON sub."SubjectID" = c."SubjectID"
    JOIN   "Students"           s   ON s."StudentID" = ss."StudentID"
    WHERE  ss."ClassStatus" = 2          -- completed
      AND  sub."CategoryID"  = 'ENG'     -- English courses
    GROUP BY s."StudentID", s."StudLastName"
),
ranked AS (
    /* rank each student by how many have grades >= theirs */
    SELECT  ec."LastName",
            ec."Grade",
            (SELECT COUNT(*)
             FROM english_completers ec2
             WHERE ec2."Grade" >= ec."Grade") AS "Rank"
    FROM english_completers ec
),
tot AS (SELECT COUNT(*) AS n FROM english_completers)
SELECT  r."LastName",
        CASE
            WHEN 1.0 * r."Rank" / tot.n <= 0.20 THEN 'First'
            WHEN 1.0 * r."Rank" / tot.n <= 0.40 THEN 'Second'
            WHEN 1.0 * r."Rank" / tot.n <= 0.60 THEN 'Third'
            WHEN 1.0 * r."Rank" / tot.n <= 0.80 THEN 'Fourth'
            ELSE                                   'Fifth'
        END AS "Quintile"
FROM   ranked r, tot
ORDER BY
    CASE
        WHEN 1.0 * r."Rank" / tot.n <= 0.20 THEN 1
        WHEN 1.0 * r."Rank" / tot.n <= 0.40 THEN 2
        WHEN 1.0 * r."Rank" / tot.n <= 0.60 THEN 3
        WHEN 1.0 * r."Rank" / tot.n <= 0.80 THEN 4
        ELSE                                   5
    END,
    r."Rank";