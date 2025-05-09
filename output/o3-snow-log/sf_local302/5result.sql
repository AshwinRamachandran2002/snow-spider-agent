WITH pivot_date AS (
    SELECT TO_DATE('2020-06-15') AS pivot_dt
), 

weekly AS (
    SELECT  
        TO_DATE("week_date",'YYYY-MM-DD')              AS week_dt,
        "region",
        "platform",
        "age_band",
        "demographic",
        "customer_type",
        "sales"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CLEANED_WEEKLY_SALES
), 

filtered AS (
    SELECT  w.*
    FROM    weekly w
    CROSS JOIN pivot_date p
    WHERE   week_dt >= DATEADD('week', -12, p.pivot_dt)   -- 12 weeks before
      AND   week_dt <  DATEADD('week',  12, p.pivot_dt)   -- 12 weeks after
),  

agg AS (
    SELECT
        "region",
        "platform",
        "age_band",
        "demographic",
        "customer_type",
        SUM(CASE WHEN week_dt <  (SELECT pivot_dt FROM pivot_date) THEN "sales" ELSE 0 END) AS sales_before,
        SUM(CASE WHEN week_dt >= (SELECT pivot_dt FROM pivot_date) THEN "sales" ELSE 0 END) AS sales_after
    FROM filtered
    GROUP BY "region","platform","age_band","demographic","customer_type"
),  

pct AS (
    /* turn each attribute into (attribute_type, attribute_value, pct_change) rows */
    SELECT 'region'        AS attribute_type, "region"        AS attribute_value,
           CASE WHEN sales_before = 0 THEN NULL
                ELSE (sales_after - sales_before) * 100.0 / sales_before END   AS pct_change
    FROM agg
    UNION ALL
    SELECT 'platform',     "platform",
           CASE WHEN sales_before = 0 THEN NULL
                ELSE (sales_after - sales_before) * 100.0 / sales_before END
    FROM agg
    UNION ALL
    SELECT 'age_band',     "age_band",
           CASE WHEN sales_before = 0 THEN NULL
                ELSE (sales_after - sales_before) * 100.0 / sales_before END
    FROM agg
    UNION ALL
    SELECT 'demographic',  "demographic",
           CASE WHEN sales_before = 0 THEN NULL
                ELSE (sales_after - sales_before) * 100.0 / sales_before END
    FROM agg
    UNION ALL
    SELECT 'customer_type',"customer_type",
           CASE WHEN sales_before = 0 THEN NULL
                ELSE (sales_after - sales_before) * 100.0 / sales_before END
    FROM agg
),  

avg_pct AS (
    SELECT
        attribute_type,
        AVG(pct_change) AS avg_pct_change           -- average % change for the attribute type
    FROM pct
    GROUP BY attribute_type
)

SELECT
    attribute_type,
    avg_pct_change,
    CASE WHEN RANK() OVER (ORDER BY avg_pct_change ASC NULLS LAST) = 1
         THEN 'HIGHEST_NEGATIVE_IMPACT' 
         ELSE NULL END AS impact_flag
FROM avg_pct
ORDER BY avg_pct_change ASC NULLS LAST;