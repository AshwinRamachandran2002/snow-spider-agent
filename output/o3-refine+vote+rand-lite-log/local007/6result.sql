WITH valid_players AS (
    SELECT
        player_id,
        debut,
        final_game
    FROM player
    WHERE debut  IS NOT NULL AND debut  <> ''
      AND final_game IS NOT NULL AND final_game <> ''
),
parts AS (
    SELECT
        player_id,
        ROUND(ABS(CAST(strftime('%Y', final_game) AS INTEGER) - CAST(strftime('%Y', debut) AS INTEGER)), 2)              AS years_part,
        ROUND(ABS(CAST(strftime('%m', final_game) AS INTEGER) - CAST(strftime('%m', debut) AS INTEGER)) / 12.0, 2)        AS months_part,
        ROUND(ABS(CAST(strftime('%d', final_game) AS INTEGER) - CAST(strftime('%d', debut) AS INTEGER)) / 365.0, 2)       AS days_part
    FROM valid_players
),
career_spans AS (
    SELECT
        player_id,
        years_part + months_part + days_part AS career_span
    FROM parts
)
SELECT ROUND(AVG(career_span), 4) AS average_single_career_span_years
FROM career_spans;