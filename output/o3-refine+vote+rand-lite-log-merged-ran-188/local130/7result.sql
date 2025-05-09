WITH english_completed AS (
    /* 1.  Every student who has COMPLETED (ClassStatus = 2) an English class       */
    /*     (Subjects whose CategoryID = 'ENG').                                     */
    /* 2.  Compute each student’s AVERAGE grade in those English classes so that    */
    /*     every student appears only once in the data set.                         */
    SELECT  ss."StudentID",
            AVG(ss."Grade") AS AvgGrade
    FROM    "Student_Schedules" ss
            JOIN "Classes"   c   ON c."ClassID"   = ss."ClassID"
            JOIN "Subjects"  sbj ON sbj."SubjectID" = c."SubjectID"
    WHERE   ss."ClassStatus" = 2          -- completed
      AND   sbj."CategoryID" = 'ENG'      -- English classes
    GROUP BY ss."StudentID"
)

SELECT  st."StudLastName" AS "LastName",

        /* -----------------------------------------------------------------------
           Determine quintile.
           rank_val = number of students whose (average) grade is >= this student.
           total    = total number of students who completed English courses.
           ---------------------------------------------------------------------*/
        CASE
            WHEN 1.0 *
                 (SELECT COUNT(*) FROM english_completed ec2
                   WHERE ec2.AvgGrade >= ec1.AvgGrade)
                 / (SELECT COUNT(*) FROM english_completed)  <= 0.20 THEN 'First'
            WHEN 1.0 *
                 (SELECT COUNT(*) FROM english_completed ec2
                   WHERE ec2.AvgGrade >= ec1.AvgGrade)
                 / (SELECT COUNT(*) FROM english_completed)  <= 0.40 THEN 'Second'
            WHEN 1.0 *
                 (SELECT COUNT(*) FROM english_completed ec2
                   WHERE ec2.AvgGrade >= ec1.AvgGrade)
                 / (SELECT COUNT(*) FROM english_completed)  <= 0.60 THEN 'Third'
            WHEN 1.0 *
                 (SELECT COUNT(*) FROM english_completed ec2
                   WHERE ec2.AvgGrade >= ec1.AvgGrade)
                 / (SELECT COUNT(*) FROM english_completed)  <= 0.80 THEN 'Fourth'
            ELSE 'Fifth'
        END                                                   AS "Quintile"

FROM    english_completed ec1
        JOIN "Students" st ON st."StudentID" = ec1."StudentID"

/*  Order results from the highest‑performing quintile to the lowest.  */
ORDER BY CASE
            WHEN 1.0 *
                 (SELECT COUNT(*) FROM english_completed ec2
                   WHERE ec2.AvgGrade >= ec1.AvgGrade)
                 / (SELECT COUNT(*) FROM english_completed)  <= 0.20 THEN 1
            WHEN 1.0 *
                 (SELECT COUNT(*) FROM english_completed ec2
                   WHERE ec2.AvgGrade >= ec1.AvgGrade)
                 / (SELECT COUNT(*) FROM english_completed)  <= 0.40 THEN 2
            WHEN 1.0 *
                 (SELECT COUNT(*) FROM english_completed ec2
                   WHERE ec2.AvgGrade >= ec1.AvgGrade)
                 / (SELECT COUNT(*) FROM english_completed)  <= 0.60 THEN 3
            WHEN 1.0 *
                 (SELECT COUNT(*) FROM english_completed ec2
                   WHERE ec2.AvgGrade >= ec1.AvgGrade)
                 / (SELECT COUNT(*) FROM english_completed)  <= 0.80 THEN 4
            ELSE 5
         END,
         st."StudLastName";