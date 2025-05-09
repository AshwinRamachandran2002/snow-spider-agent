/*--------------------------------------------------------------------
  1. Tag each week as falling in the 12-week “before” or “after” window
     around the reference date 15-Jun-2020.
  2. For every attribute type (region, platform, age_band, demographic,
     customer_type) aggregate total sales for the two periods.
  3. For every attribute value, calculate % change
        (after – before) / before * 100.
  4. For each attribute type, average the % changes of all its values.
  5. Return the attribute type whose average % change is the lowest
     (i.e., biggest negative impact) together with that value.
--------------------------------------------------------------------*/
WITH tagged_weeks AS (   -- step-1
    SELECT
        TO_DATE("week_date")                                   AS week_dt,
        "region",
        "platform",
        "age_band",
        "demographic",
        "customer_type",
        "sales",
        CASE
            WHEN DATEDIFF('week', TO_DATE('2020-06-15'), TO_DATE("week_date"))
                 BETWEEN -12 AND -1 THEN 'before'
            WHEN DATEDIFF('week', TO_DATE('2020-06-15'), TO_DATE("week_date"))
                 BETWEEN  0  AND 11 THEN 'after'
        END                                                    AS period
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CLEANED_WEEKLY_SALES
),
/*------------------------------------------------------------------*/
summary AS (               -- step-2 : total sales per attribute value & period
    SELECT 'region'      AS attribute_type, "region"      AS attribute_value, period, SUM("sales") AS total_sales
      FROM tagged_weeks WHERE period IS NOT NULL GROUP BY "region"    , period
    UNION ALL
    SELECT 'platform'    , "platform"    , period, SUM("sales")       FROM tagged_weeks WHERE period IS NOT NULL GROUP BY "platform"  , period
    UNION ALL
    SELECT 'age_band'    , "age_band"    , period, SUM("sales")       FROM tagged_weeks WHERE period IS NOT NULL GROUP BY "age_band"  , period
    UNION ALL
    SELECT 'demographic' , "demographic" , period, SUM("sales")       FROM tagged_weeks WHERE period IS NOT NULL GROUP BY "demographic", period
    UNION ALL
    SELECT 'customer_type', "customer_type", period, SUM("sales")     FROM tagged_weeks WHERE period IS NOT NULL GROUP BY "customer_type", period
),
/*------------------------------------------------------------------*/
pct_change AS (            -- step-3 : % change per attribute value
    SELECT
        attribute_type,
        attribute_value,
        MAX(CASE WHEN period = 'before' THEN total_sales END) AS before_sales,
        MAX(CASE WHEN period = 'after'  THEN total_sales END) AS after_sales,
        CASE
            WHEN MAX(CASE WHEN period = 'before' THEN total_sales END) = 0
                 OR MAX(CASE WHEN period = 'before' THEN total_sales END) IS NULL
            THEN NULL
            ELSE ( MAX(CASE WHEN period = 'after'  THEN total_sales END)
                 - MAX(CASE WHEN period = 'before' THEN total_sales END) )
                 / MAX(CASE WHEN period = 'before' THEN total_sales END) * 100
        END AS pct_change
    FROM summary
    GROUP BY attribute_type, attribute_value
),
/*------------------------------------------------------------------*/
avg_pct AS (               -- step-4 : average % change per attribute type
    SELECT
        attribute_type,
        ROUND(AVG(pct_change), 4) AS avg_pct_change
    FROM pct_change
    WHERE pct_change IS NOT NULL
    GROUP BY attribute_type
)
/*------------------------------------------------------------------*/
-- step-5 : attribute type with the most negative impact
SELECT
    attribute_type,
    avg_pct_change
FROM avg_pct
ORDER BY avg_pct_change ASC NULLS LAST
LIMIT 1;