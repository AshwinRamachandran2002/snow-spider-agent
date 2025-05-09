WITH revenue_per_submission AS (
    SELECT 
        qs."submission_number",
        SUM(qs."value") AS "revenue_usd"
    FROM SEC_QUARTERLY_FINANCIALS.SEC_QUARTERLY_FINANCIALS.QUICK_SUMMARY qs
    WHERE qs."measure_tag" IN ('Revenues', 'SalesRevenueNet', 'SalesRevenueGoodsNet')
      AND qs."number_of_quarters" = 4               -- full-year data
      AND qs."fiscal_year"        = 2016            -- fiscal year 2016
    GROUP BY qs."submission_number"
), revenue_with_state AS (
    SELECT 
        sub."stprba"                                 AS "state",
        rps."revenue_usd" / 1e9                      AS "revenue_billions"
    FROM revenue_per_submission rps
    JOIN SEC_QUARTERLY_FINANCIALS.SEC_QUARTERLY_FINANCIALS.SUBMISSION sub
      ON rps."submission_number" = sub."submission_number"
    WHERE sub."stprba" IS NOT NULL
      AND TRIM(sub."stprba") <> ''                  -- exclude blank states
)
SELECT 
    "state",
    SUM("revenue_billions") AS "total_revenue_billions"
FROM revenue_with_state
GROUP BY "state"
ORDER BY "total_revenue_billions" DESC NULLS LAST
LIMIT 1;