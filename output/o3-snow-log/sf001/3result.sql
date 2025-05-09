/*  U.S. daily snowfall > 6" for the week (Jan 15 – Jan 21) that follows the
    first two full weeks of the previous calendar year.  “Today” is assumed
    to be 2024-04-01, so the target year is 2023.                                   */

WITH bounds AS (
    SELECT
        DATE_TRUNC('YEAR', DATEADD(YEAR, -1, CURRENT_DATE()))               AS start_of_prev_year,   -- 2023-01-01
        DATEADD(DAY, 14, DATE_TRUNC('YEAR', DATEADD(YEAR, -1, CURRENT_DATE()))) AS week_start,        -- 2023-01-15
        DATEADD(DAY, 20, DATE_TRUNC('YEAR', DATEADD(YEAR, -1, CURRENT_DATE()))) AS week_end          -- 2023-01-21
)

SELECT
    "POSTAL_CODE",
    "DATE_VALID_STD",
    CAST("TOT_SNOWFALL_IN" AS FLOAT) AS "SNOWFALL_IN"
FROM GLOBAL_WEATHER__CLIMATE_DATA_FOR_BI.STANDARD_TILE.HISTORY_DAY
CROSS JOIN bounds
WHERE "COUNTRY" = 'US'
  AND CAST("TOT_SNOWFALL_IN" AS FLOAT) > 6                                   -- snowfall threshold
  AND "DATE_VALID_STD" BETWEEN bounds.week_start AND bounds.week_end          -- 2023-01-15 .. 2023-01-21
ORDER BY
    "SNOWFALL_IN" DESC NULLS LAST;