WITH rev_per_submission AS (   -- one annual revenue figure per filing
    SELECT 
        qs."submission_number",
        MAX(qs."value")                AS "revenue_value",           -- avoid double-counting if multiple tags appear
        s."stprba"                     AS "state"
    FROM SEC_QUARTERLY_FINANCIALS.SEC_QUARTERLY_FINANCIALS."QUICK_SUMMARY" qs
    JOIN SEC_QUARTERLY_FINANCIALS.SEC_QUARTERLY_FINANCIALS."SUBMISSION"     s
         ON qs."submission_number" = s."submission_number"
    WHERE qs."measure_tag" IN ('Revenues',
                               'SalesRevenueNet',
                               'SalesRevenueGoodsNet')          -- revenue tags of interest
      AND qs."number_of_quarters" = 4                           -- full-year figures
      AND qs."fiscal_year"      = 2016                          -- fiscal year 2016
      AND s."stprba" IS NOT NULL                                -- keep only rows with a state
      AND TRIM(s."stprba") <> ''
    GROUP BY qs."submission_number", s."stprba"
), state_totals AS (          -- aggregate to the state level
    SELECT 
        "state",
        SUM("revenue_value")/1e9  AS "total_revenue_billion"    -- convert to billions
    FROM rev_per_submission
    GROUP BY "state"
)
SELECT 
    "state",
    "total_revenue_billion"
FROM state_totals
ORDER BY "total_revenue_billion" DESC NULLS LAST
LIMIT 1;