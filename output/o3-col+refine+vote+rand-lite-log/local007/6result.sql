WITH span_parts AS (
  SELECT
    player_id,
    -- round each component to two decimals
    ROUND(ABS(CAST(substr(final_game,1,4) AS INTEGER) -
              CAST(substr(debut,1,4) AS INTEGER)), 2)                     AS yrs,
    ROUND(ABS(CAST(substr(final_game,6,2) AS INTEGER) -
              CAST(substr(debut,6,2) AS INTEGER)) / 12.0, 2)             AS months_part,
    ROUND(ABS(CAST(substr(final_game,9,2) AS INTEGER) -
              CAST(substr(debut,9,2) AS INTEGER)) / 365.0, 2)            AS days_part
  FROM player
  WHERE debut <> '' AND final_game <> ''
),
career_spans AS (
  SELECT
    player_id,
    yrs + months_part + days_part AS career_span
  FROM span_parts
)
SELECT ROUND(AVG(career_span), 4) AS average_career_span_years
FROM career_spans;