WITH actor_years AS (
    -- 1) Every distinct (actor, year) pair
    SELECT DISTINCT TRIM(c."PID")       AS "PID",
           CAST(m."year" AS INT)        AS "yr"
    FROM   "M_Cast"  AS c
    JOIN   "Movie"   AS m
           ON c."MID" = m."MID"
    WHERE  m."year" IS NOT NULL
),
gaps AS (
    -- 2) Year-to-year gaps within each actor’s career
    SELECT ay."PID",
           ay."yr" - LAG(ay."yr")
                     OVER (PARTITION BY ay."PID" ORDER BY ay."yr") AS "gap"
    FROM   actor_years ay
),
max_gap_per_actor AS (
    -- 3) Largest gap any actor ever had
    SELECT "PID",
           COALESCE(MAX("gap"), 0) AS "max_gap"
    FROM   gaps
    GROUP  BY "PID"
)
-- 4) Actors whose biggest gap never exceeds three years
SELECT COUNT(*) AS "actors_without_4_year_gap"
FROM   max_gap_per_actor
WHERE  "max_gap" <= 3;