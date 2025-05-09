SELECT 
    c."region"                                                  AS "region",
    MEDIAN(i."value")                                           AS "median_gdp_constant_2015_usd"
FROM WORLD_BANK.WORLD_BANK_WDI.INDICATORS_DATA        i
JOIN WORLD_BANK.WORLD_BANK_WDI.COUNTRY_SUMMARY        c
      ON i."country_code" = c."country_code"
WHERE i."indicator_code" = 'NY.GDP.MKTP.KD'     -- GDP (constant 2015 US$)
  AND c."region" IS NOT NULL                   -- exclude aggregate rows with no region
  AND i."value" IS NOT NULL                    -- ignore missing GDP values
GROUP BY c."region"
ORDER BY "median_gdp_constant_2015_usd" DESC NULLS LAST
LIMIT 1;