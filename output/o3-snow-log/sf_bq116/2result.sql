SELECT
    s."stprba"                                          AS "state",
    SUM(q."value") / 1e9                               AS "total_revenue_billions"
FROM
    "SEC_QUARTERLY_FINANCIALS"."SEC_QUARTERLY_FINANCIALS"."QUICK_SUMMARY" q
JOIN
    "SEC_QUARTERLY_FINANCIALS"."SEC_QUARTERLY_FINANCIALS"."SUBMISSION"      s
      ON q."submission_number" = s."submission_number"
WHERE
      q."fiscal_year"          = 2016
  AND q."number_of_quarters"   = 4
  AND q."measure_tag" IN ('Revenues',
                          'SalesRevenueNet',
                          'SalesRevenueGoodsNet')
  AND UPPER(q."units")         = 'USD'
  AND s."stprba" IS NOT NULL
  AND TRIM(s."stprba") <> ''
GROUP BY
    s."stprba"
ORDER BY
    "total_revenue_billions" DESC NULLS LAST
LIMIT 1;