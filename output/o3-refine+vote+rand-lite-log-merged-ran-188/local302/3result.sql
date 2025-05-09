WITH date_bounds AS (
    /* 12 weeks (84 days) either side of 15‑Jun‑2020 */
    SELECT
        date('2020-06-15','-84 days') AS before_start,
        date('2020-06-15')            AS pivot_date,
        date('2020-06-15','+84 days') AS after_end
),

/* -------- aggregate sales for every attribute value in each period -------- */
attribute_sales AS (

    /* ---------- region ---------- */
    SELECT 'region' AS attribute_type,
           region   AS attribute_val,
           'before' AS period,
           SUM(sales) AS total_sales
    FROM cleaned_weekly_sales, date_bounds
    WHERE week_date >= before_start AND week_date <  pivot_date
    GROUP BY region
    UNION ALL
    SELECT 'region', region, 'after', SUM(sales)
    FROM cleaned_weekly_sales, date_bounds
    WHERE week_date >  pivot_date AND week_date <= after_end
    GROUP BY region

    /* ---------- platform ---------- */
    UNION ALL
    SELECT 'platform', platform, 'before', SUM(sales)
    FROM cleaned_weekly_sales, date_bounds
    WHERE week_date >= before_start AND week_date <  pivot_date
    GROUP BY platform
    UNION ALL
    SELECT 'platform', platform, 'after', SUM(sales)
    FROM cleaned_weekly_sales, date_bounds
    WHERE week_date >  pivot_date AND week_date <= after_end
    GROUP BY platform

    /* ---------- age_band ---------- */
    UNION ALL
    SELECT 'age_band', age_band, 'before', SUM(sales)
    FROM cleaned_weekly_sales, date_bounds
    WHERE week_date >= before_start AND week_date <  pivot_date
    GROUP BY age_band
    UNION ALL
    SELECT 'age_band', age_band, 'after', SUM(sales)
    FROM cleaned_weekly_sales, date_bounds
    WHERE week_date >  pivot_date AND week_date <= after_end
    GROUP BY age_band

    /* ---------- demographic ---------- */
    UNION ALL
    SELECT 'demographic', demographic, 'before', SUM(sales)
    FROM cleaned_weekly_sales, date_bounds
    WHERE week_date >= before_start AND week_date <  pivot_date
    GROUP BY demographic
    UNION ALL
    SELECT 'demographic', demographic, 'after', SUM(sales)
    FROM cleaned_weekly_sales, date_bounds
    WHERE week_date >  pivot_date AND week_date <= after_end
    GROUP BY demographic

    /* ---------- customer_type ---------- */
    UNION ALL
    SELECT 'customer_type', customer_type, 'before', SUM(sales)
    FROM cleaned_weekly_sales, date_bounds
    WHERE week_date >= before_start AND week_date <  pivot_date
    GROUP BY customer_type
    UNION ALL
    SELECT 'customer_type', customer_type, 'after', SUM(sales)
    FROM cleaned_weekly_sales, date_bounds
    WHERE week_date >  pivot_date AND week_date <= after_end
    GROUP BY customer_type
),

/* -------- bring before & after together -------- */
sales_pivot AS (
    SELECT
        attribute_type,
        attribute_val,
        SUM(CASE WHEN period = 'before' THEN total_sales ELSE 0 END) AS sales_before,
        SUM(CASE WHEN period = 'after'  THEN total_sales ELSE 0 END) AS sales_after
    FROM attribute_sales
    GROUP BY attribute_type, attribute_val
),

/* -------- percentage change for each attribute value -------- */
pct_change AS (
    SELECT
        attribute_type,
        attribute_val,
        sales_before,
        sales_after,
        CASE
            WHEN sales_before = 0 THEN NULL      /* avoid division by zero */
            ELSE (sales_after - sales_before) * 100.0 / sales_before
        END AS pct_change
    FROM sales_pivot
),

/* -------- average percentage change for each attribute type -------- */
avg_change AS (
    SELECT
        attribute_type,
        AVG(pct_change) AS avg_pct_change
    FROM pct_change
    WHERE pct_change IS NOT NULL
    GROUP BY attribute_type
)

/* -------- attribute type with the greatest negative impact -------- */
SELECT
    attribute_type,
    ROUND(avg_pct_change,4) AS avg_pct_change
FROM avg_change
ORDER BY avg_pct_change ASC   /* most negative first */
LIMIT 1;