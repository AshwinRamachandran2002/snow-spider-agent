WITH player_dates AS (
    SELECT
        player_id,
        TRY_TO_DATE(debut)      AS debut_date,
        TRY_TO_DATE(final_game) AS final_date
    FROM BASEBALL.BASEBALL.PLAYER
    WHERE TRY_TO_DATE(debut) IS NOT NULL
      AND TRY_TO_DATE(final_game) IS NOT NULL
), 

diffs AS (
    SELECT
        player_id,
        /* full-year difference */
        DATEDIFF('year', debut_date, final_date)                                         AS years_diff,

        /* leftover months after removing full years */
        DATEDIFF(
            'month',
            DATEADD('year', DATEDIFF('year', debut_date, final_date), debut_date),
            final_date
        )                                                                                AS months_diff,

        /* leftover days after removing full years and full months */
        DATEDIFF(
            'day',
            DATEADD(
                'month',
                DATEDIFF(
                    'month',
                    DATEADD('year', DATEDIFF('year', debut_date, final_date), debut_date),
                    final_date
                ),
                DATEADD('year', DATEDIFF('year', debut_date, final_date), debut_date)
            ),
            final_date
        )                                                                                AS days_diff
    FROM player_dates
), 

career_spans AS (
    SELECT
        player_id,
        ROUND(ABS(years_diff),       2)                        AS years_part,
        ROUND(ABS(months_diff) / 12, 2)                        AS months_part,
        ROUND(ABS(days_diff)  / 365, 2)                        AS days_part,
        /* summed (already rounded) career span */
        ROUND(ABS(years_diff),       2) +
        ROUND(ABS(months_diff) / 12, 2) +
        ROUND(ABS(days_diff)  / 365, 2)                        AS career_span
    FROM diffs
)

SELECT
    ROUND(AVG(career_span), 4)::FLOAT AS average_career_span
FROM career_spans;