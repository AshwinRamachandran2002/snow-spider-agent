WITH english_grades AS (                    -- every completed English-class grade
    SELECT  st."StudLastName"   AS "LastName",
            ss."Grade"          AS "Grade"
    FROM    "Student_Schedules" ss
    JOIN    "Classes"           c   ON ss."ClassID"  = c."ClassID"
    JOIN    "Subjects"          sub ON c."SubjectID" = sub."SubjectID"
    JOIN    "Categories"        cat ON sub."CategoryID" = cat."CategoryID"
    JOIN    "Students"          st  ON ss."StudentID" = st."StudentID"
    WHERE   cat."CategoryDescription" = 'English'
      AND   ss."ClassStatus" = 2
), ranked AS (                             -- rank by grade (higher is better)
    SELECT  "LastName",
            "Grade",
            RANK()  OVER (ORDER BY "Grade" DESC) AS "rnk",
            COUNT(*) OVER ()                     AS "tot"
    FROM    english_grades
), quintiled AS (                           -- convert rank to quintile label
    SELECT  "LastName",
            CASE
                WHEN 1.0 * "rnk" / "tot" <= 0.20 THEN 'First'
                WHEN 1.0 * "rnk" / "tot" <= 0.40 THEN 'Second'
                WHEN 1.0 * "rnk" / "tot" <= 0.60 THEN 'Third'
                WHEN 1.0 * "rnk" / "tot" <= 0.80 THEN 'Fourth'
                ELSE                              'Fifth'
            END AS "Quintile"
    FROM    ranked
)
SELECT  "LastName",
        "Quintile"
FROM    quintiled
ORDER BY CASE "Quintile"                    -- First → Fifth
             WHEN 'First'  THEN 1
             WHEN 'Second' THEN 2
             WHEN 'Third'  THEN 3
             WHEN 'Fourth' THEN 4
             WHEN 'Fifth'  THEN 5
         END;