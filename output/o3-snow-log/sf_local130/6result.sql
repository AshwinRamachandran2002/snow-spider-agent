/* 1) Pull every completed (ClassStatus = 2) class-record whose subject
      belongs to the English category.
   2) Rank all of those grade records from highest to lowest.
   3) Convert the rank to a proportion (= rank ÷ total records)
      and map that proportion to a quintile label.
   4) Return the student’s last name and the quintile,
      ordering the result from “First” (top-20 %) down to “Fifth”. */

WITH english_completed AS (
    SELECT
        st."StudLastName",
        ss."Grade"
    FROM  SCHOOL_SCHEDULING.SCHOOL_SCHEDULING.STUDENT_SCHEDULES   ss
    JOIN  SCHOOL_SCHEDULING.SCHOOL_SCHEDULING.CLASSES             c   ON ss."ClassID"   = c."ClassID"
    JOIN  SCHOOL_SCHEDULING.SCHOOL_SCHEDULING.SUBJECTS            sub ON c."SubjectID"  = sub."SubjectID"
    JOIN  SCHOOL_SCHEDULING.SCHOOL_SCHEDULING.CATEGORIES          cat ON sub."CategoryID"= cat."CategoryID"
    JOIN  SCHOOL_SCHEDULING.SCHOOL_SCHEDULING.STUDENTS            st  ON ss."StudentID" = st."StudentID"
    WHERE ss."ClassStatus" = 2                       -- completed
      AND cat."CategoryDescription" = 'English'      -- English courses
),
ranked AS (
    SELECT
        "StudLastName",
        "Grade",
        RANK()  OVER (ORDER BY "Grade" DESC)      AS rnk,   -- 1 = highest grade
        COUNT(*) OVER ()                          AS total  -- total completed English grades
    FROM english_completed
),
quintiled AS (
    SELECT
        "StudLastName",
        CASE
            WHEN rnk * 1.0 / total <= 0.20 THEN 'First'
            WHEN rnk * 1.0 / total <= 0.40 THEN 'Second'
            WHEN rnk * 1.0 / total <= 0.60 THEN 'Third'
            WHEN rnk * 1.0 / total <= 0.80 THEN 'Fourth'
            ELSE                                    'Fifth'
        END                                           AS "Quintile"
    FROM ranked
)
SELECT
    "StudLastName",
    "Quintile"
FROM quintiled
ORDER BY
    CASE "Quintile"
        WHEN 'First'  THEN 1
        WHEN 'Second' THEN 2
        WHEN 'Third'  THEN 3
        WHEN 'Fourth' THEN 4
        ELSE               5
    END;