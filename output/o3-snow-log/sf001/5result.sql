/*  Daily U.S. snowfall > 6" during the week that follows the first two
    full weeks of the previous year (today assumed 01-Apr-2024)          */
WITH week_window AS (
    SELECT
        /* start of previous year */
        DATE_FROM_PARTS(EXTRACT(YEAR , CURRENT_DATE) - 1, 1, 1)                          AS yr_start ,
        /* week 3 starts after the first two complete weeks (14 days)   */
        DATEADD(WEEK , 2 ,
                DATE_FROM_PARTS(EXTRACT(YEAR , CURRENT_DATE) - 1, 1, 1))                AS wk_start
)
SELECT
    "POSTAL_CODE",
    "DATE_VALID_STD",
    /* keep full precision to 4 decimals as requested                     */
    TO_DECIMAL("TOT_SNOWFALL_IN", 10, 4) AS "TOT_SNOWFALL_IN"
FROM GLOBAL_WEATHER__CLIMATE_DATA_FOR_BI.STANDARD_TILE."HISTORY_DAY"
WHERE "COUNTRY" = 'US'
  AND "DATE_VALID_STD" BETWEEN
        (SELECT wk_start FROM week_window)
        AND DATEADD(DAY , 6 , (SELECT wk_start FROM week_window))      -- inclusive 7-day span
  AND "TOT_SNOWFALL_IN"::FLOAT > 6
ORDER BY
    "DATE_VALID_STD" NULLS LAST,
    "POSTAL_CODE";