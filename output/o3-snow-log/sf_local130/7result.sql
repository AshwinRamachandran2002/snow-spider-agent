WITH "COMPLETED_ENGLISH" AS (   -- students who finished (ClassStatus = 2) an English course
    SELECT
        ss."StudentID",
        AVG(ss."Grade") AS "AvgGrade"
    FROM
        SCHOOL_SCHEDULING.SCHOOL_SCHEDULING."STUDENT_SCHEDULES"  ss
        JOIN SCHOOL_SCHEDULING.SCHOOL_SCHEDULING."CLASSES"       c   ON c."ClassID"   = ss."ClassID"
        JOIN SCHOOL_SCHEDULING.SCHOOL_SCHEDULING."SUBJECTS"      sub ON sub."SubjectID" = c."SubjectID"
        JOIN SCHOOL_SCHEDULING.SCHOOL_SCHEDULING."CATEGORIES"    cat ON cat."CategoryID" = sub."CategoryID"
    WHERE
        ss."ClassStatus" = 2
        AND (sub."CategoryID" = 'ENG' OR cat."CategoryDescription" ILIKE 'English')
    GROUP BY
        ss."StudentID"
),
"RANKED" AS (                    -- rank each student by grade and compute total count
    SELECT
        ce."StudentID",
        ce."AvgGrade",
        COUNT(*) OVER ()                                                  AS "TotalStudents",
        COUNT(*) OVER (ORDER BY ce."AvgGrade" DESC
                       ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)  AS "RankPos"
    FROM
        "COMPLETED_ENGLISH" ce
)
SELECT
    st."StudLastName",
    CASE
        WHEN CAST(r."RankPos" AS FLOAT) / r."TotalStudents" <= 0.20 THEN 'First'
        WHEN CAST(r."RankPos" AS FLOAT) / r."TotalStudents" <= 0.40 THEN 'Second'
        WHEN CAST(r."RankPos" AS FLOAT) / r."TotalStudents" <= 0.60 THEN 'Third'
        WHEN CAST(r."RankPos" AS FLOAT) / r."TotalStudents" <= 0.80 THEN 'Fourth'
        ELSE 'Fifth'
    END AS "Quintile"
FROM
    "RANKED" r
    JOIN SCHOOL_SCHEDULING.SCHOOL_SCHEDULING."STUDENTS" st
      ON st."StudentID" = r."StudentID"
ORDER BY
    CASE                                            -- desired display order: First .. Fifth
        WHEN CAST(r."RankPos" AS FLOAT) / r."TotalStudents" <= 0.20 THEN 1
        WHEN CAST(r."RankPos" AS FLOAT) / r."TotalStudents" <= 0.40 THEN 2
        WHEN CAST(r."RankPos" AS FLOAT) / r."TotalStudents" <= 0.60 THEN 3
        WHEN CAST(r."RankPos" AS FLOAT) / r."TotalStudents" <= 0.80 THEN 4
        ELSE 5
    END,
    r."AvgGrade" DESC NULLS LAST;