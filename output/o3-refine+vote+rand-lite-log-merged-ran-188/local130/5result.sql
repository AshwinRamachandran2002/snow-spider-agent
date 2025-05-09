WITH english_grades AS (
    SELECT  s."StudLastName"            AS LastName,
            ss."Grade"                  AS Grade
    FROM    "Student_Schedules"  ss
    JOIN    "Classes"           c   ON c."ClassID"      = ss."ClassID"
    JOIN    "Subjects"          sub ON sub."SubjectID"  = c."SubjectID"
    JOIN    "Categories"        cat ON cat."CategoryID" = sub."CategoryID"
    JOIN    "Students"          s   ON s."StudentID"    = ss."StudentID"
    WHERE   ss."ClassStatus" = 2                -- completed
      AND   cat."CategoryDescription" = 'English'
),
ranked AS (
    SELECT  LastName,
            Grade,
            ROW_NUMBER() OVER (ORDER BY Grade DESC)                 AS rn,
            (SELECT COUNT(*) FROM english_grades)                  AS total_cnt
    FROM    english_grades
)
SELECT  LastName,
        CASE
            WHEN 1.0 * rn / total_cnt <= 0.20 THEN 'First'
            WHEN 1.0 * rn / total_cnt <= 0.40 THEN 'Second'
            WHEN 1.0 * rn / total_cnt <= 0.60 THEN 'Third'
            WHEN 1.0 * rn / total_cnt <= 0.80 THEN 'Fourth'
            ELSE                              'Fifth'
        END AS Quintile
FROM    ranked
ORDER BY CASE
            WHEN 1.0 * rn / total_cnt <= 0.20 THEN 1
            WHEN 1.0 * rn / total_cnt <= 0.40 THEN 2
            WHEN 1.0 * rn / total_cnt <= 0.60 THEN 3
            WHEN 1.0 * rn / total_cnt <= 0.80 THEN 4
            ELSE                               5
         END,
         LastName;