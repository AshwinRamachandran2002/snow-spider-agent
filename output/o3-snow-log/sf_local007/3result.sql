WITH player_dates AS (
    SELECT
        player_id,
        TRY_TO_DATE(NULLIF(TRIM(debut), ''))       AS debut_dt,
        TRY_TO_DATE(NULLIF(TRIM(final_game), ''))  AS final_dt
    FROM BASEBALL.BASEBALL.PLAYER
),
valid_players AS (
    SELECT *
    FROM player_dates
    WHERE debut_dt IS NOT NULL
      AND final_dt IS NOT NULL
      AND final_dt >= debut_dt
),
diffs AS (
    SELECT
        player_id,
        debut_dt,
        final_dt,
        DATEDIFF('month', debut_dt, final_dt) AS total_months
    FROM valid_players
),
components AS (
    SELECT
        player_id,
        FLOOR(total_months / 12)                              AS years_part,
        MOD(total_months, 12)                                 AS months_part,
        ABS(
            DATEDIFF('day',
                     DATEADD('month', total_months, debut_dt),
                     final_dt)
        )                                                     AS days_part
    FROM diffs
),
career_span AS (
    SELECT
        player_id,
        ROUND(CAST(years_part AS NUMBER),        2) +
        ROUND(months_part / 12.0,                2) +
        ROUND(days_part   / 365.0,               2) AS span_years
    FROM components
)
SELECT
    ROUND(AVG(span_years)::FLOAT, 4) AS average_career_span_years
FROM career_span;