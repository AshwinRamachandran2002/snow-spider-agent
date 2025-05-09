WITH "ENGLISH_SUBJECTS" AS (   -- 1. English courses (CategoryID = 'ENG')
    SELECT "SubjectID"
    FROM SCHOOL_SCHEDULING.SCHOOL_SCHEDULING.SUBJECTS
    WHERE "CategoryID" = 'ENG'
), 
"ENGLISH_CLASSES" AS (        -- 2. Classes that teach those English subjects
    SELECT "ClassID"
    FROM SCHOOL_SCHEDULING.SCHOOL_SCHEDULING.CLASSES
    WHERE "SubjectID" IN (SELECT "SubjectID" FROM "ENGLISH_SUBJECTS")
), 
"COMPLETED_ENGLISH" AS (      -- 3. Student completions (ClassStatus = 2)
    SELECT "StudentID",
           "Grade"
    FROM SCHOOL_SCHEDULING.SCHOOL_SCHEDULING.STUDENT_SCHEDULES
    WHERE "ClassStatus" = 2
      AND "ClassID"    IN (SELECT "ClassID" FROM "ENGLISH_CLASSES")
), 
"STUDENT_GRADE" AS (          -- 4.  One grade per student (average of all completed ENG classes)
    SELECT "StudentID",
           AVG("Grade") AS "AvgGrade"
    FROM "COMPLETED_ENGLISH"
    GROUP BY "StudentID"
), 
"RANKED" AS (                 -- 5.  Determine count-based percentile (≥ grade) for each student
    SELECT sg."StudentID",
           s."StudLastName",
           sg."AvgGrade",
           COUNT(*)  OVER ()                                           AS "TotalStudents",
           COUNT(*)  OVER (ORDER BY sg."AvgGrade" DESC
                          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS "CntGE"
    FROM "STUDENT_GRADE" sg
    JOIN SCHOOL_SCHEDULING.SCHOOL_SCHEDULING.STUDENTS s
      ON s."StudentID" = sg."StudentID"
), 
"QUINTILED" AS (              -- 6.  Map percentile to quintile label
    SELECT 
        "StudLastName",
        CASE
            WHEN ("CntGE"::FLOAT / "TotalStudents") <= 0.20 THEN 'First'
            WHEN ("CntGE"::FLOAT / "TotalStudents") <= 0.40 THEN 'Second'
            WHEN ("CntGE"::FLOAT / "TotalStudents") <= 0.60 THEN 'Third'
            WHEN ("CntGE"::FLOAT / "TotalStudents") <= 0.80 THEN 'Fourth'
            ELSE 'Fifth'
        END AS "Quintile"
    FROM "RANKED"
)
-- 7.  Final ordered result (First → Fifth)
SELECT "StudLastName",
       "Quintile"
FROM "QUINTILED"
ORDER BY
    CASE "Quintile"
        WHEN 'First'  THEN 1
        WHEN 'Second' THEN 2
        WHEN 'Third'  THEN 3
        WHEN 'Fourth' THEN 4
        ELSE              5
    END;