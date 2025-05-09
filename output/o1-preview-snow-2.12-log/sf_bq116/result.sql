SELECT s."stprba" AS "State", ROUND(SUM(n."VALUE") / 1000000000, 4) AS "Total_Revenue_Billions_USD"
FROM "SEC_QUARTERLY_FINANCIALS"."SEC_QUARTERLY_FINANCIALS"."NUMBERS" n
JOIN "SEC_QUARTERLY_FINANCIALS"."SEC_QUARTERLY_FINANCIALS"."SUBMISSION" s
  ON n."SUBMISSION_NUMBER" = s."submission_number"
WHERE n."MEASURE_TAG" IN ('Revenues', 'SalesRevenueNet', 'SalesRevenueGoodsNet')
  AND n."NUMBER_OF_QUARTERS" = 4
  AND s."fiscal_year" = 2016
  AND s."stprba" IS NOT NULL AND s."stprba" <> ''
GROUP BY s."stprba"
ORDER BY "Total_Revenue_Billions_USD" DESC NULLS LAST
LIMIT 1;