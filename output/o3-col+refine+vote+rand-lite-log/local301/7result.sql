WITH midweek AS (                                   -- identify the week that contains 15-Jun
    SELECT  "calendar_year",
            MIN("week_number") AS mid_week          -- (one value per year)
    FROM    "cleaned_weekly_sales"
    WHERE   "week_date" = CAST("calendar_year" AS TEXT) || '-06-15'
    GROUP   BY "calendar_year"
),
window_totals AS (                                  -- aggregate four weeks before vs after
    SELECT  c."calendar_year",
            SUM(CASE                                    -- 4 weeks leading up to 15-Jun
                    WHEN c."week_number" BETWEEN m.mid_week-4 AND m.mid_week-1
                    THEN c."sales" END) AS pre_sales,
            SUM(CASE                                    -- 4 weeks following 15-Jun
                    WHEN c."week_number" BETWEEN m.mid_week+1 AND m.mid_week+4
                    THEN c."sales" END) AS post_sales
    FROM    "cleaned_weekly_sales" AS c
    JOIN    midweek               AS m
           ON c."calendar_year" = m."calendar_year"
    WHERE   c."calendar_year" IN (2018, 2019, 2020)
    GROUP   BY c."calendar_year"
)
SELECT  "calendar_year",
        pre_sales,
        post_sales,
        ROUND(100.0 * (post_sales - pre_sales) / pre_sales, 2) AS pct_change
FROM    window_totals
ORDER BY "calendar_year";