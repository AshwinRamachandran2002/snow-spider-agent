WITH credited_years AS (
    SELECT
        TRIM(mc."PID")            AS PID,
        CAST(m."year" AS INTEGER) AS y
    FROM "M_Cast" AS mc
    JOIN "Movie"  AS m ON mc."MID" = m."MID"
    GROUP BY PID, y                       -- one row per actor-year
),
gaps AS (
    SELECT
        PID,
        y,
        LEAD(y) OVER (PARTITION BY PID ORDER BY y) AS next_y
    FROM credited_years
),
bad_actors AS (                           -- at least one 4-year empty span (diff ≥ 5)
    SELECT DISTINCT PID
    FROM gaps
    WHERE (next_y - y) > 4
)
SELECT COUNT(DISTINCT PID) AS actors_without_4_year_gap
FROM credited_years
WHERE PID NOT IN (SELECT PID FROM bad_actors);