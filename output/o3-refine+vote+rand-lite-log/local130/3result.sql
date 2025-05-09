WITH english_grades AS (      /* 1.  English grades per student (completed = 2) */
    SELECT
        ss."StudentID",
        st."StudLastName"           AS "LastName",
        AVG(ss."Grade")             AS "Grade"      -- one grade figure per student
    FROM "Student_Schedules" ss
    JOIN "Classes"    cl  ON ss."ClassID"   = cl."ClassID"
    JOIN "Subjects"   su  ON cl."SubjectID" = su."SubjectID"
    JOIN "Categories" ca  ON su."CategoryID"= ca."CategoryID"
    JOIN "Students"   st  ON ss."StudentID" = st."StudentID"
    WHERE ss."ClassStatus" = 2              -- completed
      AND ca."CategoryID"  = 'ENG'          -- English courses
    GROUP BY ss."StudentID"
),
ranked AS (                             /* 2.  Position & total for percentile */
    SELECT
        eg."LastName",
        eg."Grade",
        ( SELECT COUNT(*)               /* # students with ≥ this grade        */
          FROM english_grades eg2
          WHERE eg2."Grade" >= eg."Grade") AS "pos",
        ( SELECT COUNT(*) FROM english_grades) AS "tot"
    FROM english_grades eg
),
quintiles AS (                           /* 3.  Map percentile to quintile name*/
    SELECT
        "LastName",
        CASE
            WHEN 1.0*"pos"/"tot" <= 0.20 THEN 'First'
            WHEN 1.0*"pos"/"tot" <= 0.40 THEN 'Second'
            WHEN 1.0*"pos"/"tot" <= 0.60 THEN 'Third'
            WHEN 1.0*"pos"/"tot" <= 0.80 THEN 'Fourth'
            ELSE                          'Fifth'
        END AS "Quintile"
    FROM ranked
)
SELECT
    "LastName",
    "Quintile"
FROM quintiles
ORDER BY                                    -- 4.  Top quintile first
    CASE "Quintile"
         WHEN 'First'  THEN 1
         WHEN 'Second' THEN 2
         WHEN 'Third'  THEN 3
         WHEN 'Fourth' THEN 4
         ELSE 5
    END,
    "LastName";