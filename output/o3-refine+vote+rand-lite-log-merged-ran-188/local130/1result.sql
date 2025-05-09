WITH English_Grades AS (
    /* Completed English‑course grades */
    SELECT  st."StudLastName" AS LastName,
            sch."Grade"       AS Grade
    FROM    "Student_Schedules" sch
    JOIN    "Classes"  cls  ON cls."ClassID"   = sch."ClassID"
    JOIN    "Subjects" sub  ON sub."SubjectID" = cls."SubjectID"
    JOIN    "Students" st   ON st."StudentID"  = sch."StudentID"
    WHERE   sch."ClassStatus" = 2          -- completed
      AND   sub."CategoryID"  = 'ENG'      -- English courses
      AND   sch."Grade" IS NOT NULL
),
Ranks AS (
    /* Position each record and get total count */
    SELECT  LastName,
            Grade,
            ROW_NUMBER() OVER (ORDER BY Grade DESC) AS RankPos,
            COUNT(*)  OVER ()                       AS TotalCnt
    FROM    English_Grades
)
SELECT  LastName,
        CASE
            WHEN 1.0 * RankPos / TotalCnt <= 0.20 THEN 'First'
            WHEN 1.0 * RankPos / TotalCnt <= 0.40 THEN 'Second'
            WHEN 1.0 * RankPos / TotalCnt <= 0.60 THEN 'Third'
            WHEN 1.0 * RankPos / TotalCnt <= 0.80 THEN 'Fourth'
            ELSE                                      'Fifth'
        END AS Quintile
FROM    Ranks
ORDER BY
        CASE
            WHEN 1.0 * RankPos / TotalCnt <= 0.20 THEN 1
            WHEN 1.0 * RankPos / TotalCnt <= 0.40 THEN 2
            WHEN 1.0 * RankPos / TotalCnt <= 0.60 THEN 3
            WHEN 1.0 * RankPos / TotalCnt <= 0.80 THEN 4
            ELSE                                      5
        END,
        LastName;