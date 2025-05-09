SELECT s."stprba" AS "State", ROUND(SUM(q."value") / 1e9, 4) AS "Total_Revenue_Billions_USD"
FROM SEC_QUARTERLY_FINANCIALS.SEC_QUARTERLY_FINANCIALS."SUBMISSION" s
JOIN SEC_QUARTERLY_FINANCIALS.SEC_QUARTERLY_FINANCIALS."QUICK_SUMMARY" q
  ON s."submission_number" = q."submission_number"
WHERE q."measure_tag" IN ('Revenues', 'SalesRevenueNet', 'SalesRevenueGoodsNet')
  AND q."fiscal_year" = 2016
  AND q."number_of_quarters" = 4
  AND s."stprba" IS NOT NULL
  AND TRIM(s."stprba") <> ''
GROUP BY s."stprba"
ORDER BY "Total_Revenue_Billions_USD" DESC NULLS LAST
LIMIT 1;