WITH srk AS (          -- Shahrukh Khan’s PID
    SELECT PID
    FROM Person
    WHERE LOWER(TRIM(Name)) = 'shah rukh khan'
),
srk_movies AS (        -- all movies featuring Shahrukh Khan
    SELECT DISTINCT MID
    FROM M_Cast
    WHERE PID IN (SELECT PID FROM srk)
),
direct_coactors AS (   -- actors who have acted WITH Shahrukh Khan
    SELECT DISTINCT PID
    FROM M_Cast
    WHERE MID IN (SELECT MID FROM srk_movies)
      AND PID NOT IN (SELECT PID FROM srk)
),
second_degree AS (     -- actors who acted with a direct co‑actor but NEVER with Shahrukh
    SELECT DISTINCT mc.PID
    FROM M_Cast mc
    WHERE mc.MID IN (
        SELECT DISTINCT MID
        FROM M_Cast
        WHERE PID IN (SELECT PID FROM direct_coactors)
    )
      AND mc.PID NOT IN (SELECT PID FROM srk)
      AND mc.PID NOT IN (SELECT PID FROM direct_coactors)
)
SELECT COUNT(*) AS num_actors_with_shahrukh_number_2
FROM second_degree;