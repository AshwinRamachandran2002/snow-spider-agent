WITH player_dates AS (
    SELECT
        player_id,
        TRY_TO_DATE(TRIM(debut)     , 'YYYY-MM-DD') AS debut_date,
        TRY_TO_DATE(TRIM(final_game), 'YYYY-MM-DD') AS final_date
    FROM BASEBALL.BASEBALL.PLAYER
    WHERE TRIM(debut)      <> ''
      AND TRIM(final_game) <> ''
      AND TRY_TO_DATE(TRIM(debut)     , 'YYYY-MM-DD') IS NOT NULL
      AND TRY_TO_DATE(TRIM(final_game), 'YYYY-MM-DD') IS NOT NULL
),
diffs AS (
    /* compute absolute years, remaining months, remaining days */
    SELECT
        player_id,
        ABS(DATEDIFF(year,  debut_date, final_date))                                          AS years_diff,
        ABS(DATEDIFF(month,
                     DATEADD(year,
                             DATEDIFF(year, debut_date, final_date),
                             debut_date),
                     final_date))                                                             AS months_diff,
        ABS(DATEDIFF(day,
                     DATEADD(month,
                             DATEDIFF(month,
                                      DATEADD(year,
                                              DATEDIFF(year, debut_date, final_date),
                                              debut_date),
                                      final_date),
                             DATEADD(year,
                                     DATEDIFF(year, debut_date, final_date),
                                     debut_date)),
                     final_date))                                                             AS days_diff
    FROM player_dates
),
career_spans AS (
    /* round each component to two decimals, then sum */
    SELECT
        player_id,
        ROUND(years_diff ::NUMBER, 2)
        + ROUND(months_diff / 12.0, 2)
        + ROUND(days_diff  / 365.0, 2)                                                        AS career_span
    FROM diffs
)
SELECT
    ROUND(AVG(career_span), 4) AS average_career_span
FROM career_spans;