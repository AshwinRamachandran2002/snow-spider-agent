SELECT
    "LastName",
    "Quintile"
FROM (
    SELECT
        st."StudLastName"                                           AS "LastName",
        1.0 * ROW_NUMBER() OVER (ORDER BY ss."Grade" DESC)
            / COUNT(*) OVER ()                                      AS pct,
        CASE
            WHEN 1.0 * ROW_NUMBER() OVER (ORDER BY ss."Grade" DESC)
                 / COUNT(*) OVER () <= 0.20 THEN 'First'
            WHEN 1.0 * ROW_NUMBER() OVER (ORDER BY ss."Grade" DESC)
                 / COUNT(*) OVER () <= 0.40 THEN 'Second'
            WHEN 1.0 * ROW_NUMBER() OVER (ORDER BY ss."Grade" DESC)
                 / COUNT(*) OVER () <= 0.60 THEN 'Third'
            WHEN 1.0 * ROW_NUMBER() OVER (ORDER BY ss."Grade" DESC)
                 / COUNT(*) OVER () <= 0.80 THEN 'Fourth'
            ELSE 'Fifth'
        END                                                         AS "Quintile"
    FROM "Student_Schedules" AS ss
    JOIN "Classes"  AS c  ON c."ClassID"   = ss."ClassID"
    JOIN "Subjects" AS s  ON s."SubjectID" = c."SubjectID"
    JOIN "Students" AS st ON st."StudentID"= ss."StudentID"
    WHERE s."CategoryID" = 'ENG'
      AND ss."ClassStatus" = 2
)
ORDER BY
    CASE
        WHEN pct <= 0.20 THEN 1
        WHEN pct <= 0.40 THEN 2
        WHEN pct <= 0.60 THEN 3
        WHEN pct <= 0.80 THEN 4
        ELSE 5
    END,
    "LastName";