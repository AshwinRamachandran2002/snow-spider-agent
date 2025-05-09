WITH revenue_per_submission AS (
    SELECT 
        qs."submission_number",
        qs."value"                         AS revenue,
        sub."stprba",
        ROW_NUMBER() OVER (PARTITION BY qs."submission_number"
                           ORDER BY CASE 
                                       WHEN qs."measure_tag" = 'Revenues'           THEN 1
                                       WHEN qs."measure_tag" = 'SalesRevenueNet'    THEN 2
                                       WHEN qs."measure_tag" = 'SalesRevenueGoodsNet' THEN 3
                                       ELSE 4
                                    END)       AS rn
    FROM SEC_QUARTERLY_FINANCIALS.SEC_QUARTERLY_FINANCIALS.QUICK_SUMMARY  qs
    JOIN SEC_QUARTERLY_FINANCIALS.SEC_QUARTERLY_FINANCIALS.SUBMISSION      sub
          ON qs."submission_number" = sub."submission_number"
    WHERE qs."fiscal_year"         = 2016
      AND qs."number_of_quarters"  = 4
      AND qs."measure_tag" IN ('Revenues', 'SalesRevenueNet', 'SalesRevenueGoodsNet')
      AND sub."stprba" IS NOT NULL
      AND TRIM(sub."stprba") <> ''
)

SELECT 
    "stprba"                               AS "state",
    SUM(revenue) / 1e9                     AS "total_revenue_billions"
FROM revenue_per_submission
WHERE rn = 1                         -- use only one revenue figure per submission
GROUP BY "stprba"
ORDER BY "total_revenue_billions" DESC NULLS LAST
LIMIT 1;