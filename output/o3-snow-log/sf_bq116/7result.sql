SELECT
    s."stprba"                                           AS "state",
    ROUND(SUM(q."value")/1000000000, 4)                  AS "total_revenue_billions"
FROM  "SEC_QUARTERLY_FINANCIALS"."SEC_QUARTERLY_FINANCIALS"."QUICK_SUMMARY"  q
JOIN  "SEC_QUARTERLY_FINANCIALS"."SEC_QUARTERLY_FINANCIALS"."SUBMISSION"     s
      ON q."submission_number" = s."submission_number"
WHERE q."fiscal_year"          = 2016
  AND q."number_of_quarters"    = 4
  AND q."measure_tag" IN ('Revenues',
                          'SalesRevenueNet',
                          'SalesRevenueGoodsNet')
  AND COALESCE(TRIM(s."stprba"),'') <> ''          -- exclude NULL/blank states
  AND s."countryba" = 'US'                         -- keep U.S. filers only
  AND q."units"  ILIKE 'USD'                       -- insure dollar amounts
GROUP BY s."stprba"
ORDER BY "total_revenue_billions" DESC NULLS LAST
LIMIT 1;