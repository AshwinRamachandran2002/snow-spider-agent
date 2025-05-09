WITH date_parts AS (
    SELECT
        player_id,
        ABS(CAST(SUBSTR(final_game, 1, 4) AS INTEGER) - CAST(SUBSTR(debut, 1, 4) AS INTEGER))  AS yr_diff,
        ABS(CAST(SUBSTR(final_game, 6, 2) AS INTEGER) - CAST(SUBSTR(debut, 6, 2) AS INTEGER)) AS mo_diff,
        ABS(CAST(SUBSTR(final_game, 9, 2) AS INTEGER) - CAST(SUBSTR(debut, 9, 2) AS INTEGER)) AS day_diff
    FROM player
    WHERE debut <> '' AND final_game <> ''
),
career_spans AS (
    SELECT
        player_id,
        ROUND(yr_diff, 2)                        +
        ROUND(mo_diff / 12.0, 2)                 +
        ROUND(day_diff / 365.0, 2)  AS span_years
    FROM date_parts
)
SELECT CAST(ROUND(AVG(span_years), 4) AS REAL) AS average_single_career_span
FROM career_spans;