/*  Daily U.S. snowfall > 6" for the week that ends
    after the first two full weeks of the prior year  */

WITH target_week AS (
    /* 1. 1 Jan of previous year */
    SELECT DATEADD('year', -1, DATE_TRUNC('year', CURRENT_DATE())) AS prev_year_start
), first_full_monday AS (
    /* 2. First Monday on/after 1 Jan (start of the first full week) */
    SELECT CASE
             WHEN DAYOFWEEKISO(prev_year_start) = 1      -- already Monday
               THEN prev_year_start
             ELSE NEXT_DAY(prev_year_start, 'MONDAY')    -- next Monday
           END AS week1_start
    FROM target_week
), desired_week AS (
    /* 3. Third week (i.e., week that ends after two full weeks) */
    SELECT
        DATEADD('week', 2, week1_start)                           AS week_start,
        DATEADD('day',  6, DATEADD('week', 2, week1_start))       AS week_end
    FROM first_full_monday
)

SELECT
       h."POSTAL_CODE",
       h."DATE_VALID_STD",
       h."TOT_SNOWFALL_IN"
FROM   GLOBAL_WEATHER__CLIMATE_DATA_FOR_BI.STANDARD_TILE."HISTORY_DAY" AS h
JOIN   desired_week dw
  ON   h."DATE_VALID_STD" BETWEEN dw.week_start AND dw.week_end
WHERE  h."COUNTRY" = 'US'
  AND  h."TOT_SNOWFALL_IN" > 6
ORDER BY
       h."TOT_SNOWFALL_IN" DESC NULLS LAST;