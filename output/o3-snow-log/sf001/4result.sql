/*  Daily U.S. snowfall > 6" for the week that follows the first two full weeks
    of the previous year (today assumed to be 2024-04-01).

    Logic:
      • previous_year_start  = 2023-01-01
      • week_start           = previous_year_start + 14 days  → 2023-01-15
      • week_end             = week_start + 6 days            → 2023-01-21
*/

WITH date_range AS (
    SELECT
        DATEADD(day, 14, TRUNC(DATEADD(year, -1, CURRENT_DATE), 'YEAR')) AS week_start,
        DATEADD(day, 20, TRUNC(DATEADD(year, -1, CURRENT_DATE), 'YEAR')) AS week_end
)
SELECT
    h."POSTAL_CODE",
    h."DATE_VALID_STD" AS "DATE",
    h."TOT_SNOWFALL_IN" AS "SNOWFALL_IN"
FROM "GLOBAL_WEATHER__CLIMATE_DATA_FOR_BI"."STANDARD_TILE"."HISTORY_DAY"   h
JOIN date_range d
      ON h."DATE_VALID_STD" BETWEEN d.week_start AND d.week_end
WHERE h."COUNTRY" = 'US'
  AND h."TOT_SNOWFALL_IN" > 6
ORDER BY h."POSTAL_CODE",
         h."DATE_VALID_STD";