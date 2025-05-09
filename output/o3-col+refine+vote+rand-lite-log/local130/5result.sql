WITH english_grades AS (            -- every completed English-class grade
    SELECT st."StudLastName"     AS "LastName",
           ss."Grade"
    FROM "Student_Schedules" ss
    JOIN "Students"          st ON st."StudentID" = ss."StudentID"
    WHERE ss."ClassStatus" = 2
      AND ss."ClassID" IN ( SELECT c."ClassID"
                            FROM "Classes"   c
                            WHERE c."SubjectID" IN ( SELECT s."SubjectID"
                                                     FROM "Subjects" s
                                                     WHERE s."CategoryID" = 'ENG') )
),
tot AS (                            -- total # of English-completer students
    SELECT COUNT(DISTINCT "LastName") AS total_cnt
    FROM english_grades
),
ranked AS (                         -- position of each grade (ties share rank)
    SELECT eg."LastName",
           eg."Grade",
           RANK() OVER (ORDER BY eg."Grade" DESC)                AS rnk
    FROM english_grades eg
)
SELECT DISTINCT
       r."LastName"                         AS "StudentLastName",
       CASE                                   -- map to quintile labels
            WHEN 1.0 * r.rnk / t.total_cnt <= 0.20 THEN 'First'
            WHEN 1.0 * r.rnk / t.total_cnt <= 0.40 THEN 'Second'
            WHEN 1.0 * r.rnk / t.total_cnt <= 0.60 THEN 'Third'
            WHEN 1.0 * r.rnk / t.total_cnt <= 0.80 THEN 'Fourth'
            ELSE                                    'Fifth'
       END                                   AS "Quintile"
FROM ranked r
CROSS JOIN tot t
ORDER BY
    CASE                                       -- sort First → Fifth
        WHEN 1.0 * r.rnk / t.total_cnt <= 0.20 THEN 1
        WHEN 1.0 * r.rnk / t.total_cnt <= 0.40 THEN 2
        WHEN 1.0 * r.rnk / t.total_cnt <= 0.60 THEN 3
        WHEN 1.0 * r.rnk / t.total_cnt <= 0.80 THEN 4
        ELSE                                        5
    END;