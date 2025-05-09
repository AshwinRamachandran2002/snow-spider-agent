WITH sales_periods AS (
    SELECT 
        "region",
        "platform",
        "age_band",
        "demographic",
        "customer_type",
        TO_DATE("week_date")                                           AS week_dt,
        "sales"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CLEANED_WEEKLY_SALES
    WHERE TO_DATE("week_date") BETWEEN DATEADD(week,-12,'2020-06-15') 
                                   AND     DATEADD(week, 12,'2020-06-15')
), classified AS (
    SELECT 
        * ,
        CASE 
            WHEN week_dt >= DATEADD(week,-12,'2020-06-15') 
             AND week_dt <  '2020-06-15'                        THEN 'before'
            WHEN week_dt >  '2020-06-15' 
             AND week_dt <= DATEADD(week, 12,'2020-06-15')      THEN 'after'
        END                                                    AS period_flag
    FROM sales_periods
), unpivoted AS (
    SELECT 'region'        AS attribute_type, "region"        AS attribute_value, period_flag, AVG("sales") AS avg_sales
    FROM classified WHERE period_flag IS NOT NULL
    GROUP BY attribute_type, attribute_value, period_flag
    
    UNION ALL
    SELECT 'platform'      AS attribute_type, "platform"      AS attribute_value, period_flag, AVG("sales") AS avg_sales
    FROM classified WHERE period_flag IS NOT NULL
    GROUP BY attribute_type, attribute_value, period_flag
    
    UNION ALL
    SELECT 'age_band'      AS attribute_type, "age_band"      AS attribute_value, period_flag, AVG("sales") AS avg_sales
    FROM classified WHERE period_flag IS NOT NULL
    GROUP BY attribute_type, attribute_value, period_flag
    
    UNION ALL
    SELECT 'demographic'   AS attribute_type, "demographic"   AS attribute_value, period_flag, AVG("sales") AS avg_sales
    FROM classified WHERE period_flag IS NOT NULL
    GROUP BY attribute_type, attribute_value, period_flag
    
    UNION ALL
    SELECT 'customer_type' AS attribute_type, "customer_type" AS attribute_value, period_flag, AVG("sales") AS avg_sales
    FROM classified WHERE period_flag IS NOT NULL
    GROUP BY attribute_type, attribute_value, period_flag
), pivoted AS (
    SELECT
        attribute_type,
        attribute_value,
        MAX(CASE WHEN period_flag = 'before' THEN avg_sales END) AS before_sales,
        MAX(CASE WHEN period_flag = 'after'  THEN avg_sales END) AS after_sales
    FROM unpivoted
    GROUP BY attribute_type, attribute_value
    HAVING before_sales IS NOT NULL AND after_sales IS NOT NULL
), pct_change AS (
    SELECT
        attribute_type,
        attribute_value,
        (after_sales - before_sales) / NULLIF(before_sales,0) * 100 AS pct_change
    FROM pivoted
), attribute_summary AS (
    SELECT
        attribute_type,
        AVG(pct_change) AS avg_pct_change
    FROM pct_change
    GROUP BY attribute_type
)
SELECT 
    attribute_type,
    avg_pct_change
FROM attribute_summary
ORDER BY avg_pct_change ASC NULLS LAST
LIMIT 1;