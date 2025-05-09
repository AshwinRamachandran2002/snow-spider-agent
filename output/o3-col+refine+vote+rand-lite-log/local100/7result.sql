WITH
-- 1) performers whose name resembles “Shahrukh Khan”
shahrukh AS (
    SELECT "PID"
    FROM "Person"
    WHERE "Name" LIKE '%Shahrukh%'  COLLATE NOCASE
       OR "Name" LIKE '%Shah Rukh%' COLLATE NOCASE
       OR "Name" LIKE '%Khan%'      COLLATE NOCASE
),

-- 2) actors who have appeared in at least one film with a Shahrukh-like actor
degree1 AS (
    SELECT DISTINCT TRIM(mc2."PID") AS "PID"
    FROM "M_Cast"  mc1
    JOIN shahrukh  s   ON s."PID" = TRIM(mc1."PID")
    JOIN "M_Cast"  mc2 ON mc1."MID" = mc2."MID"
    WHERE TRIM(mc2."PID") <> s."PID"
),

-- 3) movies that feature at least one degree-1 actor
degree1_movies AS (
    SELECT DISTINCT "MID"
    FROM "M_Cast"
    WHERE TRIM("PID") IN (SELECT "PID" FROM degree1)
),

-- 4) actors whose Shahrukh-number is exactly 2
degree2 AS (
    SELECT DISTINCT TRIM("PID") AS "PID"
    FROM "M_Cast"
    WHERE "MID" IN (SELECT "MID" FROM degree1_movies)
      AND TRIM("PID") NOT IN (SELECT "PID" FROM degree1)   -- exclude degree-1
      AND TRIM("PID") NOT IN (SELECT "PID" FROM shahrukh)  -- exclude Shahrukh-like
)

SELECT COUNT(*) AS shahrukh_number_2_count
FROM degree2;