WITH diff AS (
    SELECT 
        player_id,
        ABS(julianday("final_game") - julianday("debut")) AS diff_days
    FROM player
    WHERE "debut" IS NOT NULL 
      AND "final_game" IS NOT NULL
      AND "debut" <> '' 
      AND "final_game" <> ''
),
parts AS (
    SELECT
        player_id,
        diff_days,
        CAST(diff_days / 365 AS INTEGER)                                             AS years_int,
        CAST((diff_days - CAST(diff_days / 365 AS INTEGER)*365) / 30 AS INTEGER)     AS months_int,
        (diff_days - CAST(diff_days / 365 AS INTEGER)*365) -
        CAST((diff_days - CAST(diff_days / 365 AS INTEGER)*365) / 30 AS INTEGER)*30  AS days_int
    FROM diff
),
span AS (
    SELECT
        player_id,
        ROUND(years_int, 2) +
        ROUND(months_int / 12.0, 2) +
        ROUND(days_int   / 365.0, 2)                         AS career_span
    FROM parts
)
SELECT ROUND(AVG(career_span), 4) AS average_career_span
FROM span;