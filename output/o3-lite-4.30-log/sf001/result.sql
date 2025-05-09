WITH week_window AS (
    /* Week (Monday‑Sunday) that ends right after the first two full weeks of the previous year */
    SELECT
        DATEADD(
            'WEEK',
            2,
            DATE_TRUNC('WEEK', DATE_TRUNC('YEAR', DATEADD('YEAR', -1, CURRENT_DATE())))
        ) AS wk_start
)
SELECT
    "POSTAL_CODE"                                   AS postal_code,
    TO_CHAR("DATE_VALID_STD", 'YYYY-MM-DD')         AS date,
    TO_DECIMAL("TOT_SNOWFALL_IN", 10, 4)            AS snowfall_inches
FROM GLOBAL_WEATHER__CLIMATE_DATA_FOR_BI.STANDARD_TILE."HISTORY_DAY"
JOIN week_window
  ON "DATE_VALID_STD" BETWEEN wk_start AND DATEADD('DAY', 6, wk_start)
WHERE "COUNTRY" = 'US'
  AND "TOT_SNOWFALL_IN" > 6
ORDER BY
    "DATE_VALID_STD",
    "POSTAL_CODE";