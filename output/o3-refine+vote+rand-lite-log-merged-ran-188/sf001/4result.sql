/*  Daily U.S. snowfall amounts > 6 inches  
    for the ISO-week that immediately follows
    the first two full ISO-weeks of the
    previous year (here, 2023).               */

WITH week_bounds AS (
    /* Monday of ISO-week 1 of the previous year
       (Jan-04 is guaranteed to fall in ISO-week 1) */
    SELECT
        DATEADD(
            WEEK ,                         -- move ahead two full weeks
            2 ,
            DATE_TRUNC(
                'WEEK',
                DATE_FROM_PARTS( YEAR(CURRENT_DATE) - 1 , 1 , 4 )
            )
        )                                   AS week_start ,          -- Monday 2023-01-16
        DATEADD(
            DAY ,
            6 ,
            DATEADD(
                WEEK ,
                2 ,
                DATE_TRUNC(
                    'WEEK',
                    DATE_FROM_PARTS( YEAR(CURRENT_DATE) - 1 , 1 , 4 )
                )
            )
        )                                   AS week_end             -- Sunday 2023-01-22
)

/* Pull the required snowfall observations */
SELECT
    "POSTAL_CODE",
    "DATE_VALID_STD",
    "TOT_SNOWFALL_IN"
FROM GLOBAL_WEATHER__CLIMATE_DATA_FOR_BI.STANDARD_TILE.HISTORY_DAY
JOIN week_bounds
  ON "DATE_VALID_STD" BETWEEN week_start AND week_end
WHERE "COUNTRY" = 'US'
  AND "TOT_SNOWFALL_IN" > 6
ORDER BY "POSTAL_CODE",
         "DATE_VALID_STD";