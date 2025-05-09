SELECT "StudLastName", "GradeQuintile"
FROM (
  SELECT st."StudLastName",
         NTILE(5) OVER (ORDER BY ss."Grade" DESC NULLS LAST) AS "GradeQuintile"
  FROM "SCHOOL_SCHEDULING"."SCHOOL_SCHEDULING"."STUDENTS" st
  JOIN "SCHOOL_SCHEDULING"."SCHOOL_SCHEDULING"."STUDENT_SCHEDULES" ss
    ON st."StudentID" = ss."StudentID"
  JOIN "SCHOOL_SCHEDULING"."SCHOOL_SCHEDULING"."CLASSES" c
    ON ss."ClassID" = c."ClassID"
  JOIN "SCHOOL_SCHEDULING"."SCHOOL_SCHEDULING"."SUBJECTS" s
    ON c."SubjectID" = s."SubjectID"
  WHERE s."SubjectName" ILIKE '%English%'
) sub
ORDER BY "GradeQuintile" ASC;