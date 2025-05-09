WITH base AS (
    SELECT 
        TO_DATE("week_date")                              AS week_dt,
        "sales",
        "region",
        "platform",
        "age_band",
        "demographic",
        "customer_type"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CLEANED_WEEKLY_SALES
),
filtered AS (
    -- keep only the 12-week windows before and after 15-Jun-2020
    SELECT *,
           CASE 
                 WHEN week_dt BETWEEN DATEADD(week,-12,'2020-06-15') 
                                 AND DATEADD(week,-1 ,'2020-06-15') THEN 'before'
                 WHEN week_dt BETWEEN DATEADD(week, 1 ,'2020-06-15') 
                                 AND DATEADD(week, 12,'2020-06-15') THEN 'after'
           END AS period
    FROM base
    WHERE week_dt BETWEEN DATEADD(week,-12,'2020-06-15') 
                      AND DATEADD(week, 12,'2020-06-15')
          AND week_dt <> '2020-06-15'        -- exclude the anchor week if present
),
agg_by_value AS (
          /* region */
    SELECT 'region'        AS attribute_type,
           "region"        AS attribute_value,
           SUM(CASE WHEN period='before' THEN "sales" END) AS before_sales,
           SUM(CASE WHEN period='after'  THEN "sales" END) AS after_sales
    FROM filtered
    GROUP BY "region"
    UNION ALL
          /* platform */
    SELECT 'platform',      "platform",
           SUM(CASE WHEN period='before' THEN "sales" END),
           SUM(CASE WHEN period='after'  THEN "sales" END)
    FROM filtered
    GROUP BY "platform"
    UNION ALL
          /* age band */
    SELECT 'age_band',      "age_band",
           SUM(CASE WHEN period='before' THEN "sales" END),
           SUM(CASE WHEN period='after'  THEN "sales" END)
    FROM filtered
    GROUP BY "age_band"
    UNION ALL
          /* demographic */
    SELECT 'demographic',   "demographic",
           SUM(CASE WHEN period='before' THEN "sales" END),
           SUM(CASE WHEN period='after'  THEN "sales" END)
    FROM filtered
    GROUP BY "demographic"
    UNION ALL
          /* customer type */
    SELECT 'customer_type', "customer_type",
           SUM(CASE WHEN period='before' THEN "sales" END),
           SUM(CASE WHEN period='after'  THEN "sales" END)
    FROM filtered
    GROUP BY "customer_type"
),
pct_change AS (
    SELECT 
        attribute_type,
        attribute_value,
        before_sales,
        after_sales,
        CASE 
            WHEN before_sales IS NULL OR before_sales = 0 THEN NULL
            ELSE 100.0 * (after_sales - before_sales) / before_sales
        END AS pct_change
    FROM agg_by_value
),
avg_pct_change_by_type AS (
    SELECT 
        attribute_type,
        AVG(pct_change) AS avg_pct_change
    FROM pct_change
    GROUP BY attribute_type
),
negative_impact AS (
    SELECT 
        attribute_type,
        avg_pct_change,
        RANK() OVER (ORDER BY avg_pct_change ASC) AS rnk   -- most negative = rank 1
    FROM avg_pct_change_by_type
)
SELECT 
    attribute_type,
    ROUND(avg_pct_change,4) AS avg_pct_change   -- highest negative impact
FROM negative_impact
WHERE rnk = 1;