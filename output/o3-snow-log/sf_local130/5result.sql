/*  Step-by-step
    1. Pull every completed (ClassStatus = 2) English course grade.
       – English is identified either by CATEGORY.DESCRIPTION = 'English'
         or SUBJECTS.CATEGORYID = 'ENG' (covers both possibilities).
    2. Count how many such grade-records exist (total_cnt).
    3. For each record get the descending rank (1 = best grade).
       – RANK() gives “how many grades are ≥ this grade”.
    4. Convert that rank to a proportion of the total, then map it
       into labelled quintiles.
    5. Show student last name and quintile, ordered First→Fifth.
*/
WITH "english_grades" AS (
    SELECT
        ss."StudentID",
        stu."StudLastName",
        ss."Grade"
    FROM SCHOOL_SCHEDULING.SCHOOL_SCHEDULING."STUDENT_SCHEDULES" ss
    JOIN SCHOOL_SCHEDULING.SCHOOL_SCHEDULING."CLASSES"        cl  ON ss."ClassID"   = cl."ClassID"
    JOIN SCHOOL_SCHEDULING.SCHOOL_SCHEDULING."SUBJECTS"       sub ON cl."SubjectID" = sub."SubjectID"
    JOIN SCHOOL_SCHEDULING.SCHOOL_SCHEDULING."CATEGORIES"     cat ON sub."CategoryID"= cat."CategoryID"
    JOIN SCHOOL_SCHEDULING.SCHOOL_SCHEDULING."STUDENTS"       stu ON ss."StudentID" = stu."StudentID"
    WHERE ss."ClassStatus" = 2
      AND (cat."CategoryDescription" = 'English' OR sub."CategoryID" = 'ENG')
),
"total_cte" AS (
    SELECT COUNT(*) AS "total_cnt" FROM "english_grades"
),
"ranked" AS (
    SELECT
        eg."StudLastName",
        eg."Grade",
        RANK() OVER (ORDER BY eg."Grade" DESC) AS "rank_desc"
    FROM "english_grades" eg
)
SELECT
    "StudLastName"                                        AS "StudentLastName",
    CASE
        WHEN "rank_desc" / tc."total_cnt"::FLOAT <= 0.20 THEN 'First'
        WHEN "rank_desc" / tc."total_cnt"::FLOAT <= 0.40 THEN 'Second'
        WHEN "rank_desc" / tc."total_cnt"::FLOAT <= 0.60 THEN 'Third'
        WHEN "rank_desc" / tc."total_cnt"::FLOAT <= 0.80 THEN 'Fourth'
        ELSE                                             'Fifth'
    END                                                   AS "Quintile"
FROM "ranked", "total_cte" tc
ORDER BY
    CASE
        WHEN "rank_desc" / tc."total_cnt"::FLOAT <= 0.20 THEN 1
        WHEN "rank_desc" / tc."total_cnt"::FLOAT <= 0.40 THEN 2
        WHEN "rank_desc" / tc."total_cnt"::FLOAT <= 0.60 THEN 3
        WHEN "rank_desc" / tc."total_cnt"::FLOAT <= 0.80 THEN 4
        ELSE 5
    END,
    "Grade" DESC NULLS LAST;