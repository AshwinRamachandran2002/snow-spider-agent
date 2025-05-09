WITH player_dates AS (
    SELECT 
        player_id,
        debut,
        final_game
    FROM player
    WHERE debut     IS NOT NULL AND final_game IS NOT NULL
      AND debut     <> ''        AND final_game <> ''
),
day_diff AS (                 -- total days between debut and final game
    SELECT
        player_id,
        CAST(julianday(final_game) - julianday(debut) AS INTEGER) AS days_tot
    FROM player_dates
    WHERE julianday(final_game) >= julianday(debut)
),
parts AS (                    -- split days into years / months / days
    SELECT
        player_id,
        CAST(days_tot / 365        AS INTEGER)                    AS yrs,
        CAST((days_tot % 365) / 30 AS INTEGER)                    AS mos,
        (days_tot % 365) - CAST((days_tot % 365) / 30 AS INTEGER)*30 AS dys
    FROM day_diff
),
spans AS (                    -- round each part and build career span
    SELECT
        player_id,
        ROUND(yrs, 2)                          AS yrs_part,
        ROUND(mos / 12.0, 2)                   AS mos_part,
        ROUND(dys / 365.0, 2)                  AS dys_part,
        ROUND(yrs, 2) +
        ROUND(mos / 12.0, 2) +
        ROUND(dys / 365.0, 2)                  AS career_span
    FROM parts
)
SELECT 
    ROUND(AVG(career_span), 4) AS average_single_career_span
FROM spans;