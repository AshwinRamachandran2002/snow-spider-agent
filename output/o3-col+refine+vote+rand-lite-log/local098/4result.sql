WITH actor_years AS (
    SELECT TRIM(mc."PID")              AS "PID",
           CAST(m."year" AS INTEGER)    AS "yr"
    FROM   "M_Cast"  AS mc
    JOIN   "Movie"   AS m  ON mc."MID" = m."MID"
    WHERE  m."year" IS NOT NULL AND m."year" <> ''
    GROUP  BY "PID", "yr"                       -- one entry per actor-year
),
gaps AS (
    SELECT ay."PID",
           ay."yr" - LAG(ay."yr") OVER (PARTITION BY ay."PID"
                                        ORDER BY ay."yr") AS "gap"
    FROM   actor_years AS ay
),
max_gap AS (
    SELECT "PID",
           MAX(COALESCE("gap",0)) AS "max_gap"   -- NULL for first credit → 0
    FROM   gaps
    GROUP  BY "PID"
)
SELECT COUNT(*) AS "actors_no_gap_over_3_years"
FROM   max_gap
WHERE  "max_gap" <= 3;