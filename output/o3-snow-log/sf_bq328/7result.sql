SELECT 
    cs."region",
    MEDIAN(id."value") AS median_gdp_constant_2015_usd
FROM WORLD_BANK.WORLD_BANK_WDI.INDICATORS_DATA id
JOIN WORLD_BANK.WORLD_BANK_WDI.COUNTRY_SUMMARY cs
      ON id."country_code" = cs."country_code"
WHERE id."indicator_code" = 'NY.GDP.MKTP.KD'          -- GDP (constant 2015 US$)
  AND id."value" IS NOT NULL
  AND cs."region" IS NOT NULL
GROUP BY cs."region"
ORDER BY median_gdp_constant_2015_usd DESC NULLS LAST
LIMIT 1;