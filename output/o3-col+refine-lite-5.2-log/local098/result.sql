WITH actor_years AS (
    -- every actor paired with each distinct movie year they appeared
    SELECT c."PID",
           CAST(m."year" AS INTEGER) AS yr
    FROM   "M_Cast" AS c
    JOIN   "Movie"  AS m
      ON   m."MID" = c."MID"
    GROUP  BY c."PID", yr
),
gaps AS (
    -- compute year‑to‑year gaps for each actor
    SELECT PID,
           LEAD(yr) OVER (PARTITION BY PID ORDER BY yr) - yr AS gap
    FROM   actor_years
),
actors_with_long_gap AS (
    -- actors who ever have a gap of 4+ years
    SELECT DISTINCT PID
    FROM   gaps
    WHERE  gap > 3            -- 4 or more consecutive years
),
actors_without_long_gap AS (
    -- actors who never have such a gap
    SELECT DISTINCT PID
    FROM   actor_years
    EXCEPT
    SELECT PID FROM actors_with_long_gap
)
SELECT COUNT(*) AS actors_without_4year_gap
FROM   actors_without_long_gap;