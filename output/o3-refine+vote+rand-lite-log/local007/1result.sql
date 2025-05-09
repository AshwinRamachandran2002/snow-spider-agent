WITH spans AS (
    SELECT
        player_id,
        ROUND(ABS(CAST(substr(final_game,1,4) AS INTEGER) - 
                 CAST(substr(debut,1,4) AS INTEGER)), 2)                           AS years_part,
        ROUND(ABS(CAST(substr(final_game,6,2) AS INTEGER) - 
                 CAST(substr(debut,6,2) AS INTEGER)) / 12.0, 2)                   AS months_part,
        ROUND(ABS(CAST(substr(final_game,9,2) AS INTEGER) - 
                 CAST(substr(debut,9,2) AS INTEGER)) / 365.0, 2)                  AS days_part
    FROM player
    WHERE debut      IS NOT NULL  AND debut      <> ''
      AND final_game IS NOT NULL  AND final_game <> ''
),
career AS (
    SELECT
        player_id,
        years_part + months_part + days_part AS career_span
    FROM spans
)
SELECT ROUND(AVG(career_span), 2) AS average_career_span
FROM career;