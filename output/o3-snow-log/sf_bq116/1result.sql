WITH rev AS (
    SELECT 
        qs."submission_number",
        /* convert to billions of dollars */
        qs."value" / 1e9 AS "revenue_billions",
        CASE 
            WHEN qs."measure_tag" = 'Revenues'            THEN 1
            WHEN qs."measure_tag" = 'SalesRevenueNet'     THEN 2
            WHEN qs."measure_tag" = 'SalesRevenueGoodsNet' THEN 3
        END AS "tag_order"
    FROM SEC_QUARTERLY_FINANCIALS.SEC_QUARTERLY_FINANCIALS."QUICK_SUMMARY" qs
    JOIN SEC_QUARTERLY_FINANCIALS.SEC_QUARTERLY_FINANCIALS."SUBMISSION" sub
          ON qs."submission_number" = sub."submission_number"
    WHERE qs."fiscal_year" = 2016
      AND qs."number_of_quarters" = 4               -- full-year data
      AND qs."measure_tag" IN ('Revenues',
                               'SalesRevenueNet',
                               'SalesRevenueGoodsNet')
      AND sub."stprba" IS NOT NULL
      AND TRIM(sub."stprba") <> ''                  -- exclude blank states
), unique_rev AS (                                 -- pick one revenue tag per filing
    SELECT 
        "submission_number",
        "revenue_billions",
        ROW_NUMBER() OVER (PARTITION BY "submission_number"
                           ORDER BY "tag_order") AS rn
    FROM rev
), per_submission AS (
    SELECT 
        "submission_number",
        "revenue_billions"
    FROM unique_rev
    WHERE rn = 1                                    -- keep preferred tag only
), per_state AS (
    SELECT 
        sub."stprba"                                   AS "state",
        SUM(ps."revenue_billions")                     AS "total_revenue_billions"
    FROM per_submission ps
    JOIN SEC_QUARTERLY_FINANCIALS.SEC_QUARTERLY_FINANCIALS."SUBMISSION" sub
          ON ps."submission_number" = sub."submission_number"
    GROUP BY sub."stprba"
)
SELECT 
    "state",
    "total_revenue_billions"
FROM per_state
ORDER BY "total_revenue_billions" DESC NULLS LAST
LIMIT 1;