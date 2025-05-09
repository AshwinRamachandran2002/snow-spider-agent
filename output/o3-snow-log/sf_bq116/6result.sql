/*  State with the highest total annual revenue (in billions USD) for FY 2016  */
SELECT 
       res."state",
       ROUND(res."total_revenue" / 1e9, 4) AS "total_revenue_billions_usd"
FROM (
        /*  Aggregate FY-2016 revenue across all companies, by state  */
        SELECT 
               sbm."stprba"                          AS "state",
               SUM(qs."value")                      AS "total_revenue"
        FROM   SEC_QUARTERLY_FINANCIALS.SEC_QUARTERLY_FINANCIALS.QUICK_SUMMARY  qs
        JOIN   SEC_QUARTERLY_FINANCIALS.SEC_QUARTERLY_FINANCIALS.SUBMISSION      sbm
               ON qs."submission_number" = sbm."submission_number"
        WHERE  qs."fiscal_year"         = 2016
          AND  qs."number_of_quarters"  = 4
          AND  qs."measure_tag" IN ('Revenues',
                                    'SalesRevenueNet',
                                    'SalesRevenueGoodsNet')
          AND  COALESCE(TRIM(sbm."stprba"),'') <> ''          -- exclude NULL/empty states
        GROUP BY sbm."stprba"
     ) res
ORDER BY res."total_revenue" DESC NULLS LAST
LIMIT 1;