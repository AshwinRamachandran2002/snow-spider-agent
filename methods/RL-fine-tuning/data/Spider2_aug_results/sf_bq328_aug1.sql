-- Task: What is the median GDP (constant 2015 US$) value globally in 2019?
SELECT
  ROUND(MEDIAN(id."value"), 4) AS Median_Global_GDP
FROM
  WORLD_BANK.WORLD_BANK_WDI."INDICATORS_DATA" id
WHERE
  id."indicator_code" = 'NY.GDP.MKTP.KD' AND
  id."year" = 2019 AND
  id."value" IS NOT NULL AND id."value" > 0;