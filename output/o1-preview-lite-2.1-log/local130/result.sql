SELECT "StudLastName", "QuintileRank"
FROM (
    SELECT st."StudLastName", 
           (6 - NTILE(5) OVER (ORDER BY ss."Grade" DESC)) AS "QuintileRank"
    FROM "Student_Schedules" AS ss
    JOIN "Student_Class_Status" AS scs ON ss."ClassStatus" = scs."ClassStatus"
    JOIN "Students" AS st ON ss."StudentID" = st."StudentID"
    JOIN "Classes" AS cl ON ss."ClassID" = cl."ClassID"
    JOIN "Subjects" AS s ON cl."SubjectID" = s."SubjectID"
    JOIN "Categories" AS c ON s."CategoryID" = c."CategoryID"
    WHERE scs."ClassStatusDescription" = 'Completed'
      AND c."CategoryDescription" = 'English'
)
ORDER BY "QuintileRank" DESC;