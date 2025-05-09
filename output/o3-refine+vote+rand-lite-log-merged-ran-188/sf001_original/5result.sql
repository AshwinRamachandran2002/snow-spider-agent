/* Daily U.S. snowfall amounts > 6" during the week that
   follows the first two full weeks of the previous year. */

WITH prev_year AS (  -- first day of the previous year
    SELECT DATE_TRUNC('YEAR', DATEADD(YEAR, -1, CURRENT_DATE)) AS prev_year_start
),
first_monday AS (    -- first Monday on or after Jan‑1 of that year
    SELECT
        CASE
            WHEN DAYOFWEEKISO(prev_year_start) = 1          -- 1 = Monday in ISO
                 THEN prev_year_start
            ELSE DATEADD(DAY, 8 - DAYOFWEEKISO(prev_year_start), prev_year_start)
        END AS first_monday_of_year
    FROM prev_year
),
target_week AS (     -- the 3rd full week (starts 14 days after the first Monday)
    SELECT
        DATEADD(DAY, 14, first_monday_of_year) AS week_start,  -- Monday
        DATEADD(DAY, 20, first_monday_of_year) AS week_end     -- Sunday
    FROM first_monday
)

SELECT
    H."POSTAL_CODE",
    H."DATE_VALID_STD"            AS "DATE",
    H."TOT_SNOWFALL_IN"
FROM GLOBAL_WEATHER__CLIMATE_DATA_FOR_BI.STANDARD_TILE.HISTORY_DAY H
JOIN target_week W
  ON H."DATE_VALID_STD" BETWEEN W.week_start AND W.week_end
WHERE H."COUNTRY" = 'US'
  AND H."TOT_SNOWFALL_IN" > 6
ORDER BY H."DATE_VALID_STD", H."POSTAL_CODE";