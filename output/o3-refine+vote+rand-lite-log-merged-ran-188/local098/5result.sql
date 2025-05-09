WITH actor_years AS (
    -- 1.  List every calendar year in which each actor appeared
    SELECT
        TRIM(mc."PID")               AS PID,
        CAST(m."year" AS INTEGER)    AS act_year
    FROM "M_Cast"   AS mc
    JOIN "Movie"    AS m  ON m."MID" = mc."MID"
    WHERE m."year" GLOB '[0-9]*'           -- keep only numeric years
    GROUP BY PID, act_year                 -- one row per actor-year
),
gaps AS (
    -- 2.  Compute gap to previous appearance for every actor
    SELECT
        PID,
        act_year
          - LAG(act_year) OVER (PARTITION BY PID ORDER BY act_year) 
          AS gap_len
    FROM actor_years
),
max_gaps AS (
    -- 3.  Largest gap across the whole career of each actor
    SELECT
        PID,
        COALESCE(MAX(gap_len),0) AS max_gap
    FROM gaps
    GROUP BY PID
)
-- 4.  Count actors whose longest gap never exceeds 3 years
SELECT COUNT(*) AS actors_without_4yr_gap
FROM   max_gaps
WHERE  max_gap <= 3;