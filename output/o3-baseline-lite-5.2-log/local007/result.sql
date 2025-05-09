WITH spans AS (
    SELECT
        player_id,
        ABS(CAST(substr(final_game,1,4) AS INTEGER) - CAST(substr(debut,1,4) AS INTEGER)) AS diff_years,
        ABS(CAST(substr(final_game,6,2) AS INTEGER) - CAST(substr(debut,6,2) AS INTEGER)) AS diff_months,
        ABS(CAST(substr(final_game,9,2) AS INTEGER) - CAST(substr(debut,9,2) AS INTEGER)) AS diff_days
    FROM player
    WHERE debut IS NOT NULL
      AND final_game IS NOT NULL
      AND debut <> ''
      AND final_game <> ''
      AND length(debut) = 10
      AND length(final_game) = 10
), calc AS (
    SELECT
        player_id,
        ROUND(diff_years, 2) +
        ROUND(diff_months / 12.0, 2) +
        ROUND(diff_days  / 365.0, 2) AS career_span
    FROM spans
)
SELECT ROUND(AVG(career_span), 4) AS average_career_span
FROM calc;