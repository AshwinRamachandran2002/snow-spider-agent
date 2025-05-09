/*  • “Today” is assumed to be the runtime system date.
    • We take the calendar year prior to today (previous year).
    • The first two full weeks of that year span 14 days (1 Jan – 14 Jan).
    • We therefore want the seven-day window that follows: 15 Jan – 21 Jan.         */

WITH window_dates AS (
    SELECT
        DATE_FROM_PARTS(YEAR(CURRENT_DATE) - 1, 1, 15)                 AS week_start,
        DATEADD('day', 6, DATE_FROM_PARTS(YEAR(CURRENT_DATE) - 1, 1, 15)) AS week_end
)
SELECT
    h."POSTAL_CODE",
    h."DATE_VALID_STD"                        AS "DATE",
    TO_DECIMAL(h."TOT_SNOWFALL_IN", 10, 4)    AS "SNOWFALL_IN"
FROM "GLOBAL_WEATHER__CLIMATE_DATA_FOR_BI"."STANDARD_TILE"."HISTORY_DAY" h
JOIN window_dates w
  ON h."DATE_VALID_STD" BETWEEN w.week_start AND w.week_end
WHERE h."COUNTRY" = 'US'
  AND h."TOT_SNOWFALL_IN" > 6
ORDER BY
    h."POSTAL_CODE",
    h."DATE_VALID_STD";