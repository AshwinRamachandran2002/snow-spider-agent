WITH RankedStudents AS (
    SELECT s."StudLastName", ROUND(ss."Grade", 4) AS "Grade",
        ROW_NUMBER() OVER (ORDER BY ss."Grade" DESC) AS "Rank"
    FROM "Students" s
    INNER JOIN "Student_Schedules" ss ON s."StudentID" = ss."StudentID"
    WHERE ss."ClassID" IN (
        SELECT "ClassID"
        FROM "Classes"
        WHERE "SubjectID" IN (
            SELECT "SubjectID"
            FROM "Subjects"
            WHERE "CategoryID" = (
                SELECT "CategoryID"
                FROM "Categories"
                WHERE "CategoryDescription" = 'English'
            )
        )
    )
    AND ss."ClassStatus" = (
        SELECT "ClassStatus"
        FROM "Student_Class_Status"
        WHERE "ClassStatusDescription" = 'Completed'
    )
)
SELECT "StudLastName",
    CASE
        WHEN "Rank" BETWEEN 1 AND 4 THEN 5
        WHEN "Rank" BETWEEN 5 AND 8 THEN 4
        WHEN "Rank" BETWEEN 9 AND 11 THEN 3
        WHEN "Rank" BETWEEN 12 AND 14 THEN 2
        ELSE 1
    END AS "QuintileRank"
FROM RankedStudents
ORDER BY "QuintileRank" DESC, "Grade" DESC;