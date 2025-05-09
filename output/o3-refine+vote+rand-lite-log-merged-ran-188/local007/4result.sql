WITH parsed_dates AS (
    SELECT
        player_id,
        CAST(SUBSTR(debut,1,4) AS INTEGER)  AS debut_year,
        CAST(SUBSTR(debut,6,2) AS INTEGER)  AS debut_month,
        CAST(SUBSTR(debut,9,2) AS INTEGER)  AS debut_day,
        CAST(SUBSTR(final_game,1,4) AS INTEGER) AS final_year,
        CAST(SUBSTR(final_game,6,2) AS INTEGER) AS final_month,
        CAST(SUBSTR(final_game,9,2) AS INTEGER) AS final_day
    FROM player
    WHERE debut IS NOT NULL        AND debut <> ''
      AND final_game IS NOT NULL   AND final_game <> ''
),
career_span AS (
    SELECT
        player_id,
        ROUND(ABS(final_year  - debut_year ), 2)                      AS years_part,
        ROUND(ABS(final_month - debut_month) / 12.0, 2)               AS months_part,
        ROUND(ABS(final_day   - debut_day  ) / 365.0, 2)              AS days_part
    FROM parsed_dates
),
spans AS (
    SELECT
        player_id,
        years_part + months_part + days_part AS span_years
    FROM career_span
)
SELECT ROUND(AVG(span_years), 2) AS average_single_career_span
FROM spans;