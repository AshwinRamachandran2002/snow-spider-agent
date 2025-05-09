WITH english_classes AS (
    SELECT c."ClassID"
    FROM "Classes" c
    JOIN "Subjects" s ON c."SubjectID" = s."SubjectID"
    WHERE s."CategoryID" = 'ENG'
),
english_grades AS (
    SELECT ss."StudentID",
           ss."Grade"
    FROM "Student_Schedules" ss
    JOIN english_classes ec ON ss."ClassID" = ec."ClassID"
    WHERE ss."ClassStatus" = 2
),
best_grade_per_student AS (
    SELECT "StudentID",
           MAX("Grade") AS "BestGrade"
    FROM english_grades
    GROUP BY "StudentID"
),
ranked AS (
    SELECT bg."StudentID",
           (SELECT COUNT(*)
            FROM best_grade_per_student bg2
            WHERE bg2."BestGrade" >= bg."BestGrade") AS "RankPos"
    FROM best_grade_per_student bg
),
totals AS (
    SELECT COUNT(*) AS "TotalStudents"
    FROM best_grade_per_student
),
quintiles AS (
    SELECT r."StudentID",
           CASE
               WHEN 1.0 * r."RankPos" / t."TotalStudents" <= 0.20 THEN 'First'
               WHEN 1.0 * r."RankPos" / t."TotalStudents" <= 0.40 THEN 'Second'
               WHEN 1.0 * r."RankPos" / t."TotalStudents" <= 0.60 THEN 'Third'
               WHEN 1.0 * r."RankPos" / t."TotalStudents" <= 0.80 THEN 'Fourth'
               ELSE 'Fifth'
           END AS "Quintile"
    FROM ranked r
    CROSS JOIN totals t
)
SELECT s."StudLastName" AS "LastName",
       q."Quintile"
FROM quintiles q
JOIN "Students" s ON s."StudentID" = q."StudentID"
ORDER BY CASE q."Quintile"
           WHEN 'First'  THEN 1
           WHEN 'Second' THEN 2
           WHEN 'Third'  THEN 3
           WHEN 'Fourth' THEN 4
           ELSE 5
         END,
         s."StudLastName";