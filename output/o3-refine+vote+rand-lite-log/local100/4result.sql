WITH
shahrukh AS (                       -- Shahrukh Khan’s PID(s)
    SELECT PID
    FROM Person
    WHERE lower(Name) LIKE '%shahrukh%khan%'
       OR lower(Name) LIKE '%shah rukh%khan%'
),
movies_of_shahrukh AS (             -- all movies Shahrukh acted in
    SELECT DISTINCT MID
    FROM M_Cast
    WHERE PID IN (SELECT PID FROM shahrukh)
),
level1 AS (                         -- actors who acted WITH Shahrukh (distance 1)
    SELECT DISTINCT PID
    FROM M_Cast
    WHERE MID IN (SELECT MID FROM movies_of_shahrukh)
      AND PID NOT IN (SELECT PID FROM shahrukh)
),
movies_of_level1 AS (               -- every movie that any level‑1 actor is in
    SELECT DISTINCT MID
    FROM M_Cast
    WHERE PID IN (SELECT PID FROM level1)
),
level2_raw AS (                     -- everyone who acted with a level‑1 actor
    SELECT DISTINCT PID
    FROM M_Cast
    WHERE MID IN (SELECT MID FROM movies_of_level1)
      AND PID NOT IN (SELECT PID FROM shahrukh)   -- exclude Shahrukh himself
),
level2 AS (                         -- keep only those who NEVER acted with Shahrukh
    SELECT PID
    FROM level2_raw
    WHERE PID NOT IN (SELECT PID FROM level1)
)
SELECT COUNT(DISTINCT PID) AS num_actors_shahrukh_number_2
FROM level2;