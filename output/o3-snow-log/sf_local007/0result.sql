WITH valid_players AS (
    SELECT 
        player_id,
        TRY_TO_DATE(debut)      AS debut_date,
        TRY_TO_DATE(final_game) AS final_date
    FROM BASEBALL.BASEBALL.PLAYER
    WHERE TRY_TO_DATE(debut)      IS NOT NULL
      AND TRY_TO_DATE(final_game) IS NOT NULL
),
ordered_dates AS (   -- guarantee start_date <= end_date
    SELECT
        player_id,
        CASE WHEN debut_date <= final_date THEN debut_date ELSE final_date END AS start_date,
        CASE WHEN debut_date <= final_date THEN final_date ELSE debut_date END AS end_date
    FROM valid_players
),
date_parts AS (      -- obtain non-overlapping Y/M/D differences
    SELECT
        player_id,
        FLOOR(DATEDIFF('month', start_date, end_date) / 12)                   AS years_diff,
        MOD(DATEDIFF('month', start_date, end_date), 12)                      AS months_diff,
        DATEDIFF(
            'day',
            DATEADD('month', DATEDIFF('month', start_date, end_date), start_date),
            end_date
        )                                                                     AS days_diff
    FROM ordered_dates
),
span_components AS ( -- round each part to two decimals
    SELECT
        player_id,
        ROUND(ABS(years_diff), 2)                       AS years_part,
        ROUND(ABS(months_diff) / 12.0, 2)               AS months_part,
        ROUND(ABS(days_diff)   / 365.0, 2)              AS days_part
    FROM date_parts
),
player_spans AS (    -- sum the rounded parts for each player
    SELECT
        player_id,
        years_part + months_part + days_part            AS career_span
    FROM span_components
)
SELECT 
    ROUND(AVG(career_span), 4) AS average_career_span
FROM player_spans;