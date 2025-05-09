WITH English_Grades AS (          -- all completed English‑class grades
    SELECT SS.StudentID,
           SS.Grade
    FROM   "Student_Schedules" SS
           JOIN "Classes"  C  ON C."ClassID"  = SS."ClassID"
           JOIN "Subjects" S  ON S."SubjectID" = C."SubjectID"
    WHERE  SS."ClassStatus" = 2          -- 2 = Completed
      AND  S."CategoryID"   = 'ENG'      -- English courses
),
Student_Avg AS (                 -- one row per student, average grade
    SELECT StudentID,
           AVG(Grade) AS AvgGrade
    FROM   English_Grades
    GROUP  BY StudentID
),
Total_Cnt AS (                   -- total number of English students
    SELECT COUNT(*) AS N
    FROM   Student_Avg
),
Ranks AS (                        -- “how many students scored >= me”
    SELECT A.StudentID,
           A.AvgGrade,
           (SELECT COUNT(*) FROM Student_Avg B
             WHERE B.AvgGrade >= A.AvgGrade) AS RankPos
    FROM   Student_Avg A
)
SELECT  ST."StudLastName"                   AS "LastName",
        CASE
            WHEN 1.0*R.RankPos/N <= 0.20 THEN 'First'
            WHEN 1.0*R.RankPos/N <= 0.40 THEN 'Second'
            WHEN 1.0*R.RankPos/N <= 0.60 THEN 'Third'
            WHEN 1.0*R.RankPos/N <= 0.80 THEN 'Fourth'
            ELSE                                   'Fifth'
        END                                  AS "Quintile"
FROM    Ranks      R
        CROSS JOIN Total_Cnt
        JOIN "Students" ST ON ST."StudentID" = R."StudentID"
ORDER BY
        CASE                           -- Highest‑to‑lowest quintile
            WHEN 1.0*R.RankPos/N <= 0.20 THEN 1
            WHEN 1.0*R.RankPos/N <= 0.40 THEN 2
            WHEN 1.0*R.RankPos/N <= 0.60 THEN 3
            WHEN 1.0*R.RankPos/N <= 0.80 THEN 4
            ELSE                               5
        END,
        ST."StudLastName";