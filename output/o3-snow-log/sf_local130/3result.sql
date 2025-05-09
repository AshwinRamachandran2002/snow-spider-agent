WITH english_completions AS (
    /* All completed (ClassStatus = 2) English courses */
    SELECT
        stu."StudLastName"                           AS "LastName",
        sch."Grade"
    FROM SCHOOL_SCHEDULING.SCHOOL_SCHEDULING.STUDENT_SCHEDULES sch
    JOIN SCHOOL_SCHEDULING.SCHOOL_SCHEDULING.CLASSES cls
         ON cls."ClassID" = sch."ClassID"
    JOIN SCHOOL_SCHEDULING.SCHOOL_SCHEDULING.SUBJECTS sub
         ON sub."SubjectID" = cls."SubjectID"
    JOIN SCHOOL_SCHEDULING.SCHOOL_SCHEDULING.STUDENTS stu
         ON stu."StudentID" = sch."StudentID"
    WHERE sch."ClassStatus" = 2
      AND sub."CategoryID"  = 'ENG'     -- English subjects
),
ranked AS (
    /* Rank each completion by grade (higher-is-better) and capture total count */
    SELECT
        ec.*,
        RANK()      OVER (ORDER BY ec."Grade" DESC) AS "rank_pos",
        COUNT(*)    OVER ()                         AS "total_cnt"
    FROM english_completions ec
),
quintiled AS (
    /* Convert rank to quintile label */
    SELECT
        "LastName",
        CASE
            WHEN "rank_pos" * 1.0 / "total_cnt" <= 0.20 THEN 'First'
            WHEN "rank_pos" * 1.0 / "total_cnt" <= 0.40 THEN 'Second'
            WHEN "rank_pos" * 1.0 / "total_cnt" <= 0.60 THEN 'Third'
            WHEN "rank_pos" * 1.0 / "total_cnt" <= 0.80 THEN 'Fourth'
            ELSE 'Fifth'
        END AS "Quintile"
    FROM ranked
)
SELECT
    "LastName",
    "Quintile"
FROM quintiled
ORDER BY
    CASE "Quintile"
        WHEN 'First'  THEN 1
        WHEN 'Second' THEN 2
        WHEN 'Third'  THEN 3
        WHEN 'Fourth' THEN 4
        WHEN 'Fifth'  THEN 5
    END ASC;