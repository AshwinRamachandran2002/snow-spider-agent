/* ---------------------------------------------------------------
   Daily U.S. snowfall > 6 inches during the week that ends
   AFTER the first two full weeks of the *previous* year.
   – “Today” is assumed to be 2024-04-01, so the previous year is 2023.
   – “Full week” is treated as Sunday-through-Saturday.
   – The target week therefore spans Sun-15-Jan-2023 … Sat-21-Jan-2023.
-----------------------------------------------------------------*/
WITH year_start AS (      -- 2023-01-01
    SELECT DATEADD(year, -1, DATE_TRUNC('year', CURRENT_DATE)) AS y_start
), first_sunday AS (      -- first Sunday on/after 01-Jan-2023  →  2023-01-01
    SELECT DATEADD(day, MOD(7 - DAYOFWEEK(y_start), 7), y_start) AS sun0
    FROM year_start
), target_week AS (       -- week #3 → 2023-01-15 … 2023-01-21
    SELECT
        DATEADD(day, 14, sun0) AS week_start,   -- Sunday
        DATEADD(day, 20, sun0) AS week_end      -- Saturday
    FROM first_sunday
)
SELECT
    h."POSTAL_CODE",
    h."DATE_VALID_STD",
    h."TOT_SNOWFALL_IN"
FROM
    "GLOBAL_WEATHER__CLIMATE_DATA_FOR_BI"."STANDARD_TILE"."HISTORY_DAY" h,
    target_week w
WHERE
    h."COUNTRY" = 'US'
    AND h."TOT_SNOWFALL_IN" > 6
    AND h."DATE_VALID_STD" BETWEEN w.week_start AND w.week_end
ORDER BY
    h."DATE_VALID_STD",
    h."POSTAL_CODE";