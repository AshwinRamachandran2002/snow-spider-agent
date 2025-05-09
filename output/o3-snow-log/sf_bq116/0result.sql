SELECT
    sub."stprba"                                     AS "state",
    ROUND(SUM(qs."value")/1000000000, 4)            AS "total_revenue_billions"
FROM
    "SEC_QUARTERLY_FINANCIALS"."SEC_QUARTERLY_FINANCIALS"."QUICK_SUMMARY"  qs
JOIN
    "SEC_QUARTERLY_FINANCIALS"."SEC_QUARTERLY_FINANCIALS"."SUBMISSION"     sub
        ON qs."submission_number" = sub."submission_number"
WHERE
        qs."fiscal_year"           = 2016
    AND qs."number_of_quarters"    = 4
    AND qs."measure_tag" IN ('Revenues','SalesRevenueNet','SalesRevenueGoodsNet')
    AND qs."units"                 = 'USD'
    AND sub."stprba" IS NOT NULL
    AND TRIM(sub."stprba")        <> ''
GROUP BY
    sub."stprba"
ORDER BY
    "total_revenue_billions" DESC NULLS LAST
LIMIT 1;