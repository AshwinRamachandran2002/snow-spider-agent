WITH week_dates AS (
    /* Monday of the first week of the previous year */
    SELECT
        DATEADD(
            DAY,
            CASE 
                WHEN DAYOFWEEK(year_start) = 1      -- Sunday
                     THEN 1                         -- next day (Monday)
                ELSE 9 - DAYOFWEEK(year_start)      -- shift forward to Monday
            END,
            year_start
        ) AS wk1_monday
    FROM (
        SELECT DATE_TRUNC('YEAR', DATEADD(YEAR, -1, CURRENT_DATE())) AS year_start
    )
), target_week AS (
    /* Monday that starts the week AFTER the first two full weeks */
    SELECT DATEADD(DAY, 14, wk1_monday) AS wk_start
    FROM   week_dates
)

SELECT
    "POSTAL_CODE",
    "DATE_VALID_STD"                           AS "SNOW_DATE",
    "TOT_SNOWFALL_IN"::FLOAT                   AS "SNOWFALL_IN"
FROM "GLOBAL_WEATHER__CLIMATE_DATA_FOR_BI"."STANDARD_TILE"."HISTORY_DAY" hd
JOIN target_week tw
  ON hd."DATE_VALID_STD" BETWEEN tw.wk_start
                             AND DATEADD(DAY, 6, tw.wk_start)   -- Monday-Sunday span
WHERE hd."COUNTRY" = 'US'
  AND hd."TOT_SNOWFALL_IN"::FLOAT > 6
ORDER BY "SNOWFALL_IN" DESC NULLS LAST;