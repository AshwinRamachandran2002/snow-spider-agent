SELECT c."region", ROUND(MEDIAN(d."value"), 4) AS "Median_GDP"
FROM WORLD_BANK.WORLD_BANK_WDI.INDICATORS_DATA d
JOIN WORLD_BANK.WORLD_BANK_WDI.COUNTRY_SUMMARY c
ON d."country_code" = c."country_code"
WHERE d."indicator_code" = 'NY.GDP.MKTP.KD' AND d."year" = 2019 AND c."region" <> ''
GROUP BY c."region"
ORDER BY "Median_GDP" DESC NULLS LAST
LIMIT 1;