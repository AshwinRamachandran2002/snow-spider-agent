-- Task: For the year 2019, determine which region has the highest median GDP (in constant 2015 US$) calculated across the countries in that region.
SELECT
  cs."region" AS Region,
  ROUND(MEDIAN(id."value"), 4) AS Median_GDP
FROM
  WORLD_BANK.WORLD_BANK_WDI."INDICATORS_DATA" id
JOIN
  WORLD_BANK.WORLD_BANK_WDI."COUNTRY_SUMMARY" cs
ON
  id."country_code" = cs."country_code"
WHERE
  id."indicator_code" = 'NY.GDP.MKTP.KD' AND
  id."year" = 2019 AND
  id."value" IS NOT NULL AND id."value" > 0 AND
  cs."region" IS NOT NULL AND cs."region" <> ''
GROUP BY
  cs."region"
ORDER BY
  Median_GDP DESC NULLS LAST
LIMIT 1;