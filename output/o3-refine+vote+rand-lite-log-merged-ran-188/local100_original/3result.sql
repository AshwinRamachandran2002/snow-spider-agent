WITH
shahrukh AS (
    SELECT PID
    FROM Person
    WHERE TRIM(Name) LIKE '%Shah%rukh%Khan%'
),
movies_shahrukh AS (          -- movies that feature Shahrukh Khan
    SELECT DISTINCT MID
    FROM M_Cast
    WHERE PID IN (SELECT PID FROM shahrukh)
),
actors1 AS (                  -- actors who acted WITH Shahrukh (Shahrukh‑number = 1)
    SELECT DISTINCT PID
    FROM M_Cast
    WHERE MID IN (SELECT MID FROM movies_shahrukh)
      AND PID NOT IN (SELECT PID FROM shahrukh)
),
actors2 AS (                  -- actors who acted with an actor1, but never with Shahrukh
    SELECT DISTINCT mc2.PID
    FROM M_Cast mc1
    JOIN M_Cast mc2
      ON mc1.MID = mc2.MID
    WHERE mc1.PID IN (SELECT PID FROM actors1)          -- movie has an actor1
      AND mc2.PID NOT IN (SELECT PID FROM shahrukh)     -- exclude Shahrukh
      AND mc2.PID NOT IN (SELECT PID FROM actors1)      -- exclude actors with number 1
)
SELECT COUNT(*) AS actors_with_shahrukh_number_2
FROM actors2;