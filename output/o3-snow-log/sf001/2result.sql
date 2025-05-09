SELECT
    "POSTAL_CODE",
    "DATE_VALID_STD",
    "TOT_SNOWFALL_IN"
FROM
    GLOBAL_WEATHER__CLIMATE_DATA_FOR_BI.STANDARD_TILE."HISTORY_DAY"
WHERE
    "COUNTRY" = 'US'
    AND EXTRACT(YEAR FROM "DATE_VALID_STD") = 2024            -- previous winter season year
    AND "DOY_STD" BETWEEN 15 AND 21                           -- week ending after the first two full weeks
    AND TO_NUMBER("TOT_SNOWFALL_IN") > 6                      -- daily snowfall greater than 6 inches
ORDER BY
    TO_NUMBER("TOT_SNOWFALL_IN") DESC NULLS LAST;