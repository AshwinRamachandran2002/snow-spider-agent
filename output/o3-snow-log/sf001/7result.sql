/*  Daily U.S. snowfall > 6" during the 3rd week (days 15-21) of last year  */
WITH "WEEK_BOUNDS" AS (
    SELECT
        /* first day of previous year → add 14 days to reach day-15 (week start) */
        DATEADD(day, 14,
                DATEADD(year, -1, DATE_TRUNC('year', CURRENT_DATE()))
        ) AS "START_DATE",
        /* day-15 + 6 days = day-21 (week end) */
        DATEADD(day, 20,
                DATEADD(year, -1, DATE_TRUNC('year', CURRENT_DATE()))
        ) AS "END_DATE"
)
SELECT
    h."POSTAL_CODE",
    h."DATE_VALID_STD"               AS "DATE",
    h."TOT_SNOWFALL_IN"              AS "SNOWFALL_IN"
FROM "GLOBAL_WEATHER__CLIMATE_DATA_FOR_BI"."STANDARD_TILE"."HISTORY_DAY" h
CROSS JOIN "WEEK_BOUNDS" wb
WHERE h."COUNTRY" = 'US'
  AND h."DATE_VALID_STD" BETWEEN wb."START_DATE" AND wb."END_DATE"
  AND h."TOT_SNOWFALL_IN" > 6
ORDER BY
    h."DATE_VALID_STD",
    h."POSTAL_CODE";