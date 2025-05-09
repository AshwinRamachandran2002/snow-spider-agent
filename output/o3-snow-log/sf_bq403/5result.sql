/*  Smallest gaps between the medians of revenue and functional expenses
    for Form-990 filers, by filing year (2012-2017)                      */
SELECT  "filing_year",
        ABS("median_revenue" - "median_expenses") AS "median_diff"
FROM   (
        /* ----- 2012 filings ----- */
        SELECT '2012' AS "filing_year",
               MEDIAN("totrevenue")   AS "median_revenue",
               MEDIAN("totfuncexpns") AS "median_expenses"
        FROM   IRS_990.IRS_990."IRS_990_2012"
        WHERE  "totrevenue"   IS NOT NULL
          AND  "totfuncexpns" IS NOT NULL
        
        UNION ALL
        
        /* ----- 2013 filings ----- */
        SELECT '2013',
               MEDIAN("totrevenue"),
               MEDIAN("totfuncexpns")
        FROM   IRS_990.IRS_990."IRS_990_2013"
        WHERE  "totrevenue"   IS NOT NULL
          AND  "totfuncexpns" IS NOT NULL
        
        UNION ALL
        
        /* ----- 2014 filings ----- */
        SELECT '2014',
               MEDIAN("totrevenue"),
               MEDIAN("totfuncexpns")
        FROM   IRS_990.IRS_990."IRS_990_2014"
        WHERE  "totrevenue"   IS NOT NULL
          AND  "totfuncexpns" IS NOT NULL
        
        UNION ALL
        
        /* ----- 2015 filings ----- */
        SELECT '2015',
               MEDIAN("totrevenue"),
               MEDIAN("totfuncexpns")
        FROM   IRS_990.IRS_990."IRS_990_2015"
        WHERE  "totrevenue"   IS NOT NULL
          AND  "totfuncexpns" IS NOT NULL
        
        UNION ALL
        
        /* ----- 2016 filings ----- */
        SELECT '2016',
               MEDIAN("totrevenue"),
               MEDIAN("totfuncexpns")
        FROM   IRS_990.IRS_990."IRS_990_2016"
        WHERE  "totrevenue"   IS NOT NULL
          AND  "totfuncexpns" IS NOT NULL
        
        UNION ALL
        
        /* ----- 2017 filings ----- */
        SELECT '2017',
               MEDIAN("totrevenue"),
               MEDIAN("totfuncexpns")
        FROM   IRS_990.IRS_990."IRS_990_2017"
        WHERE  "totrevenue"   IS NOT NULL
          AND  "totfuncexpns" IS NOT NULL
) t
ORDER BY "median_diff" ASC NULLS LAST
LIMIT 3;