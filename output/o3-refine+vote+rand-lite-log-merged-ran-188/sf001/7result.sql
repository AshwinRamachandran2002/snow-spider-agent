/*  Daily U.S. snowfall > 6" for the FIRST “week-ending” period that occurs
    AFTER the first two full weeks of the previous year (2023).

    Approach
    ────────
    1.  Treat weeks as the 7-day span that begins on a MONDAY
        (Snowflake DATE_TRUNC('WEEK', …) convention) and ends
        on the following SUNDAY.

    2.  Discard all rows dated on/before 14 Jan 2023
        (the end of the first two complete weeks of 2023).

    3.  From the remaining rows with snowfall > 6", find the
        earliest week-ending date (the SUNDAY of that week).

    4.  Return every U.S. daily-history record within that one
        target week, showing postal code, date, and snowfall.               */

WITH snowfall_gt6 AS (   -- rows after 14-Jan-2023 with >6" snowfall
    SELECT
        h."POSTAL_CODE",
        h."DATE_VALID_STD",
        h."TOT_SNOWFALL_IN",
        DATEADD(DAY, 6, DATE_TRUNC('WEEK', h."DATE_VALID_STD")) AS week_end   -- Sunday
    FROM GLOBAL_WEATHER__CLIMATE_DATA_FOR_BI.STANDARD_TILE.HISTORY_DAY h
    WHERE h."COUNTRY" = 'US'
      AND h."TOT_SNOWFALL_IN" > 6
      AND h."DATE_VALID_STD" > DATE '2023-01-14'            -- after first two full weeks
      AND h."DATE_VALID_STD" < DATE '2024-01-01'            -- stay within previous year
),
first_target_week AS (    -- earliest week-ending date that qualifies
    SELECT MIN(week_end) AS week_end
    FROM snowfall_gt6
)
SELECT
    s."POSTAL_CODE"     AS "postal_code",
    s."DATE_VALID_STD"  AS "date",
    s."TOT_SNOWFALL_IN" AS "snowfall_in"
FROM snowfall_gt6   s
JOIN first_target_week t
  ON s.week_end = t.week_end           -- keep only that one week
ORDER BY s."POSTAL_CODE", s."DATE_VALID_STD";