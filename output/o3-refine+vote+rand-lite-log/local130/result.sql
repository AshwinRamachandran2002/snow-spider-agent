WITH English_Grades AS (
    /* 1. English courses that are completed (ClassStatus = 2) */
    SELECT  st."StudLastName",
            ss."Grade"
    FROM    "Student_Schedules"  ss
    JOIN    "Classes"            cl  ON cl."ClassID"  = ss."ClassID"
    JOIN    "Subjects"           sb  ON sb."SubjectID" = cl."SubjectID"
    JOIN    "Categories"         ca  ON ca."CategoryID" = sb."CategoryID"
    JOIN    "Students"           st  ON st."StudentID" = ss."StudentID"
    WHERE   ss."ClassStatus" = 2
      AND   (ca."CategoryDescription" = 'English' OR ca."CategoryID" = 'ENG')
      AND   ss."Grade" IS NOT NULL
),
Ranked AS (
    /* 2. Work out how many grades are ≥ each grade
          and the overall total, so we can build quintiles. */
    SELECT  eg."StudLastName",
            eg."Grade",
            COUNT(*) OVER ()                                            AS total_grades,
            COUNT(*) OVER (ORDER BY eg."Grade" DESC
                           ROWS BETWEEN UNBOUNDED PRECEDING
                                    AND CURRENT ROW)                    AS ge_count
    FROM    English_Grades eg
)
SELECT  "StudLastName"                         AS "LastName",
        CASE
             WHEN (1.0 * ge_count) / total_grades <= 0.20 THEN 'First'
             WHEN (1.0 * ge_count) / total_grades <= 0.40 THEN 'Second'
             WHEN (1.0 * ge_count) / total_grades <= 0.60 THEN 'Third'
             WHEN (1.0 * ge_count) / total_grades <= 0.80 THEN 'Fourth'
             ELSE                                             'Fifth'
        END                                     AS "Quintile"
FROM    Ranked
ORDER BY
        CASE
             WHEN (1.0 * ge_count) / total_grades <= 0.20 THEN 1
             WHEN (1.0 * ge_count) / total_grades <= 0.40 THEN 2
             WHEN (1.0 * ge_count) / total_grades <= 0.60 THEN 3
             WHEN (1.0 * ge_count) / total_grades <= 0.80 THEN 4
             ELSE                                             5
        END,
        "StudLastName";