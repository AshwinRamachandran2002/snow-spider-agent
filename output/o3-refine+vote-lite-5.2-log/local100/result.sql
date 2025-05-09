WITH
shahrukh AS (          -- Shah Rukh Khan’s PID
    SELECT PID
    FROM Person
    WHERE Name LIKE '%Shahrukh%Khan%'
    LIMIT 1
),

shah_movies AS (       -- Movies featuring Shah Rukh Khan
    SELECT DISTINCT MID
    FROM M_Cast
    WHERE PID = (SELECT PID FROM shahrukh)
),

direct1 AS (           -- Actors who acted directly with Shah Rukh Khan
    SELECT DISTINCT PID
    FROM M_Cast
    WHERE MID IN (SELECT MID FROM shah_movies)
      AND PID <> (SELECT PID FROM shahrukh)
),

secondlevel AS (       -- Actors who acted with a “direct‑1” actor but never with Shah Rukh Khan
    SELECT DISTINCT mc2.PID
    FROM M_Cast mc1
    JOIN M_Cast mc2 ON mc1.MID = mc2.MID
    WHERE mc1.PID IN (SELECT PID FROM direct1)
      AND mc2.PID NOT IN (SELECT PID FROM direct1)
      AND mc2.PID <> (SELECT PID FROM shahrukh)
)

SELECT COUNT(*) AS actors_with_shahrukh_number_2
FROM secondlevel;