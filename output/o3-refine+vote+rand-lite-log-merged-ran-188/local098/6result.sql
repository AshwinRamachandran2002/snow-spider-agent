WITH actor_years AS (        -- every distinct year an actor appeared
    SELECT mc."PID",
           CAST(m."year" AS INTEGER) AS act_year
    FROM   "M_Cast" mc
    JOIN   "Movie"  m ON m."MID" = mc."MID"
    GROUP BY mc."PID", act_year
),
gaps AS (                    -- year-to-year gaps inside each career
    SELECT PID,
           act_year,
           LAG(act_year) OVER (PARTITION BY PID ORDER BY act_year) AS prev_year
    FROM   actor_years
),
bad_actors AS (              -- actors who ever had a gap ≥ 4 years
    SELECT DISTINCT PID
    FROM   gaps
    WHERE  prev_year IS NOT NULL
      AND  act_year - prev_year > 3
)
SELECT COUNT(DISTINCT PID) AS num_actors_no_long_gap
FROM   actor_years
WHERE  PID NOT IN (SELECT PID FROM bad_actors);