WITH student_avg_grades AS (
    SELECT s."StudLastName",
           AVG(ss."Grade") AS "AverageGrade"
    FROM SCHOOL_SCHEDULING.SCHOOL_SCHEDULING.STUDENTS s
    JOIN SCHOOL_SCHEDULING.SCHOOL_SCHEDULING.STUDENT_SCHEDULES ss
        ON s."StudentID" = ss."StudentID"
    JOIN SCHOOL_SCHEDULING.SCHOOL_SCHEDULING.CLASSES c
        ON ss."ClassID" = c."ClassID"
    JOIN SCHOOL_SCHEDULING.SCHOOL_SCHEDULING.SUBJECTS subj
        ON c."SubjectID" = subj."SubjectID"
    JOIN SCHOOL_SCHEDULING.SCHOOL_SCHEDULING.STUDENT_CLASS_STATUS scs
        ON ss."ClassStatus" = scs."ClassStatus"
    JOIN SCHOOL_SCHEDULING.SCHOOL_SCHEDULING.CATEGORIES cat
        ON subj."CategoryID" = cat."CategoryID"
    WHERE scs."ClassStatusDescription" = 'Completed'
      AND cat."CategoryDescription" = 'English'
      AND ss."Grade" IS NOT NULL
    GROUP BY s."StudentID", s."StudLastName"
)
SELECT "StudLastName",
       NTILE(5) OVER (ORDER BY "AverageGrade" DESC NULLS LAST) AS "GradeQuintile"
FROM student_avg_grades
ORDER BY "GradeQuintile" ASC, "StudLastName" ASC;