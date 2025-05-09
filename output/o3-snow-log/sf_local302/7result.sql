WITH base_data AS (
    SELECT
        TO_DATE("week_date", 'YYYY-MM-DD') AS wk_date,
        "region",
        "platform",
        "age_band",
        "demographic",
        "customer_type",
        "sales"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CLEANED_WEEKLY_SALES
),
periodised AS (
    SELECT
        *,
        CASE
            WHEN wk_date BETWEEN DATEADD(day, -84, DATE '2020-06-15')
                             AND DATEADD(day, -1,  DATE '2020-06-15')  THEN 'before'
            WHEN wk_date BETWEEN DATE '2020-06-15'
                             AND DATEADD(day,  83, DATE '2020-06-15')  THEN 'after'
        END AS period
    FROM base_data
    WHERE wk_date BETWEEN DATEADD(day, -84, DATE '2020-06-15')
                      AND DATEADD(day,  83, DATE '2020-06-15')
),
period_sales AS (
    SELECT
        "region",
        "platform",
        "age_band",
        "demographic",
        "customer_type",
        period,
        SUM("sales") AS sales_sum
    FROM periodised
    GROUP BY "region", "platform", "age_band", "demographic",
             "customer_type", period
),
before_after AS (
    SELECT
        "region",
        "platform",
        "age_band",
        "demographic",
        "customer_type",
        MAX(CASE WHEN period = 'before' THEN sales_sum END) AS before_sales,
        MAX(CASE WHEN period = 'after'  THEN sales_sum END) AS after_sales
    FROM period_sales
    GROUP BY "region", "platform", "age_band", "demographic", "customer_type"
),
pct_change_calc AS (
    SELECT
        "region",
        "platform",
        "age_band",
        "demographic",
        "customer_type",
        before_sales,
        after_sales,
        CASE
            WHEN before_sales IS NULL OR before_sales = 0
                 THEN NULL
            ELSE (after_sales - before_sales) / before_sales * 100
        END AS pct_change
    FROM before_after
),
unpivot_attr AS (
    SELECT 'region'        AS attr_type, "region"        AS attr_value, pct_change FROM pct_change_calc
    UNION ALL
    SELECT 'platform'      AS attr_type, "platform"      AS attr_value, pct_change FROM pct_change_calc
    UNION ALL
    SELECT 'age_band'      AS attr_type, "age_band"      AS attr_value, pct_change FROM pct_change_calc
    UNION ALL
    SELECT 'demographic'   AS attr_type, "demographic"   AS attr_value, pct_change FROM pct_change_calc
    UNION ALL
    SELECT 'customer_type' AS attr_type, "customer_type" AS attr_value, pct_change FROM pct_change_calc
),
avg_change_by_attr AS (
    SELECT
        attr_type,
        AVG(pct_change) AS avg_pct_change
    FROM unpivot_attr
    WHERE pct_change IS NOT NULL
    GROUP BY attr_type
),
highest_negative AS (
    SELECT
        attr_type,
        avg_pct_change
    FROM avg_change_by_attr
    ORDER BY avg_pct_change ASC NULLS LAST
    LIMIT 1
)
SELECT
    attr_type      AS "attribute_type_with_highest_negative_impact",
    avg_pct_change AS "average_percentage_change"
FROM highest_negative;