/*---------------------------------------------------------------
  Daily U.S. snowfall > 6" during the week that immediately
  follows the first two full ISO weeks (Mon-Sun) of the
  previous calendar year (relative to CURRENT_DATE()).
----------------------------------------------------------------*/
WITH
prev_year_dates AS (
    /* Previous calendar year based on today */
    SELECT
        YEAR(CURRENT_DATE()) - 1          AS prev_year,
        DATE_FROM_PARTS(YEAR(CURRENT_DATE()) - 1, 1, 1) AS first_day_prev_year
),
first_monday AS (
    /* First ISO-week Monday of the previous year */
    SELECT
        CASE
            /* If Jan-1 is already a Monday (ISO = 1) keep it,
               else jump forward to the next Monday. */
            WHEN DAYOFWEEKISO(first_day_prev_year) = 1
                 THEN first_day_prev_year
            ELSE DATEADD(
                     day,
                     8 - DAYOFWEEKISO(first_day_prev_year),
                     first_day_prev_year
                 )
        END AS first_monday_prev_year
    FROM prev_year_dates
),
target_week AS (
    /* Week we need: starts 2 weeks (14 days) after first Monday,
       ends 20 days after first Monday (inclusive) */
    SELECT
        DATEADD(day, 14, first_monday_prev_year) AS week_start,
        DATEADD(day, 20, first_monday_prev_year) AS week_end
    FROM first_monday
)
SELECT
    "POSTAL_CODE",
    "DATE_VALID_STD",
    "TOT_SNOWFALL_IN"
FROM "GLOBAL_WEATHER__CLIMATE_DATA_FOR_BI"."STANDARD_TILE"."HISTORY_DAY",
     target_week
WHERE "COUNTRY" = 'US'
  AND "DATE_VALID_STD" BETWEEN target_week.week_start AND target_week.week_end
  AND "TOT_SNOWFALL_IN" > 6
ORDER BY
    "DATE_VALID_STD",
    "POSTAL_CODE";