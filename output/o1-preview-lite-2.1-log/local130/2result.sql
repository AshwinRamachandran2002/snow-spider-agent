SELECT "StudLastName", "QuintileRank"
FROM (
  SELECT "StudLastName",
         NTILE(5) OVER (ORDER BY "AvgGrade" DESC) AS "QuintileRank"
  FROM (
    SELECT st."StudLastName",
           ROUND(AVG(ss."Grade"), 4) AS "AvgGrade"
    FROM "Students" AS st
    JOIN "Student_Schedules" AS ss ON st."StudentID" = ss."StudentID"
    JOIN "Student_Class_Status" AS scs ON ss."ClassStatus" = scs."ClassStatus"
    JOIN "Classes" AS cls ON ss."ClassID" = cls."ClassID"
    JOIN "Subjects" AS s ON cls."SubjectID" = s."SubjectID"
    JOIN "Categories" AS c ON s."CategoryID" = c."CategoryID"
    WHERE scs."ClassStatusDescription" = 'Completed'
      AND c."CategoryDescription" = 'English'
    GROUP BY st."StudentID", st."StudLastName"
  ) AS grades
) AS ranked
ORDER BY "QuintileRank" DESC;