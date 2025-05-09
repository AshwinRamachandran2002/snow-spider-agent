WITH windowed AS (
    SELECT
        "week_date",
        "region",
        "platform",
        "age_band",
        "demographic",
        "customer_type",
        "sales",
        CASE
            WHEN "week_date" BETWEEN '2020-03-23' AND '2020-06-08' THEN 'before'
            WHEN "week_date" BETWEEN '2020-06-15' AND '2020-09-07' THEN 'after'
        END AS period
    FROM "cleaned_weekly_sales"
    WHERE "week_date" BETWEEN '2020-03-23' AND '2020-09-07'
),
pct_change AS (
    -- Region
    SELECT 'region' AS attr_type,
           "region" AS attr_value,
           (SUM(CASE WHEN period='after'  THEN sales END) * 1.0 /
            SUM(CASE WHEN period='before' THEN sales END) - 1) * 100 AS pct_change
    FROM windowed
    GROUP BY "region"
    
    UNION ALL
    -- Platform
    SELECT 'platform', "platform",
           (SUM(CASE WHEN period='after'  THEN sales END) * 1.0 /
            SUM(CASE WHEN period='before' THEN sales END) - 1) * 100
    FROM windowed
    GROUP BY "platform"
    
    UNION ALL
    -- Age band
    SELECT 'age_band', "age_band",
           (SUM(CASE WHEN period='after'  THEN sales END) * 1.0 /
            SUM(CASE WHEN period='before' THEN sales END) - 1) * 100
    FROM windowed
    GROUP BY "age_band"
    
    UNION ALL
    -- Demographic
    SELECT 'demographic', "demographic",
           (SUM(CASE WHEN period='after'  THEN sales END) * 1.0 /
            SUM(CASE WHEN period='before' THEN sales END) - 1) * 100
    FROM windowed
    GROUP BY "demographic"
    
    UNION ALL
    -- Customer type
    SELECT 'customer_type', "customer_type",
           (SUM(CASE WHEN period='after'  THEN sales END) * 1.0 /
            SUM(CASE WHEN period='before' THEN sales END) - 1) * 100
    FROM windowed
    GROUP BY "customer_type"
),
avg_change AS (
    SELECT
        attr_type,
        ROUND(AVG(pct_change), 4) AS avg_pct_change
    FROM pct_change
    GROUP BY attr_type
)
SELECT
    attr_type  AS highest_negative_impact_attr,
    avg_pct_change
FROM avg_change
ORDER BY avg_pct_change ASC
LIMIT 1;