WITH player_dates AS (
    SELECT
        PLAYER_ID,
        TRY_TO_DATE(DEBUT)      AS debut_date,
        TRY_TO_DATE(FINAL_GAME) AS final_date
    FROM BASEBALL.BASEBALL.PLAYER
),
valid_dates AS (
    SELECT *
    FROM player_dates
    WHERE debut_date IS NOT NULL
      AND final_date IS NOT NULL
),
diffs AS (
    SELECT
        PLAYER_ID,
        ABS(DATEDIFF('year' , debut_date, final_date))  AS years_diff,
        ABS(DATEDIFF('month', debut_date, final_date))  AS months_total,
        debut_date,
        final_date
    FROM valid_dates
),
components AS (
    SELECT
        PLAYER_ID,
        years_diff,
        (months_total - years_diff * 12) AS months_diff,
        ABS(DATEDIFF(
            'day',
            DATEADD('month', years_diff * 12 + (months_total - years_diff * 12), debut_date),
            final_date
        )) AS days_diff
    FROM diffs
),
rounded_parts AS (
    SELECT
        PLAYER_ID,
        ROUND(years_diff,          2) AS years_part,
        ROUND(months_diff / 12.0,  2) AS months_part,
        ROUND(days_diff   / 365.0, 2) AS days_part
    FROM components
),
career_spans AS (
    SELECT
        PLAYER_ID,
        years_part + months_part + days_part AS career_span
    FROM rounded_parts
),
average_span AS (
    SELECT
        AVG(career_span) AS avg_career_span
    FROM career_spans
)
SELECT CAST(avg_career_span AS FLOAT) AS average_career_span
FROM average_span;