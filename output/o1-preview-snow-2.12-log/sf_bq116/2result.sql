SELECT s."stprba" AS "State", ROUND(SUM(n."VALUE")/1000000000, 4) AS "Total_Revenue_Billions_USD"
FROM "SEC_QUARTERLY_FINANCIALS"."SEC_QUARTERLY_FINANCIALS"."NUMBERS" n
JOIN "SEC_QUARTERLY_FINANCIALS"."SEC_QUARTERLY_FINANCIALS"."SUBMISSION" s
    ON n."SUBMISSION_NUMBER" = s."submission_number"
WHERE s."fiscal_year" = 2016
    AND n."NUMBER_OF_QUARTERS" = 4
    AND n."MEASURE_TAG" IN ('Revenues', 'SalesRevenueNet', 'SalesRevenueGoodsNet')
    AND s."stprba" IS NOT NULL AND s."stprba" <> ''
GROUP BY s."stprba"
ORDER BY SUM(n."VALUE") DESC NULLS LAST
LIMIT 1;