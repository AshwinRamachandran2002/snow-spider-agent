WITH sales_periods AS (
    /* tag each record as belonging to the 12‑week window
       “before” or “after” 15‑Jun‑2020                      */
    SELECT
        region,
        platform,
        age_band,
        demographic,
        customer_type,
        sales,
        CASE
            WHEN date(week_date) >= date('2020-03-23')
                 AND date(week_date) <  date('2020-06-15') THEN 'before'
            WHEN date(week_date) >= date('2020-06-15')
                 AND date(week_date) <= date('2020-08-31') THEN 'after'
        END AS period
    FROM cleaned_weekly_sales
    WHERE date(week_date) BETWEEN date('2020-03-23') AND date('2020-08-31')
),

/* aggregate sales for every attribute value in each period */
agg AS (
    SELECT 'region'        AS attribute_type, region        AS attribute_value, period, SUM(sales) AS total_sales
    FROM sales_periods GROUP BY region,        period
    UNION ALL
    SELECT 'platform',       platform,       period, SUM(sales) FROM sales_periods GROUP BY platform,       period
    UNION ALL
    SELECT 'age_band',       age_band,       period, SUM(sales) FROM sales_periods GROUP BY age_band,       period
    UNION ALL
    SELECT 'demographic',    demographic,    period, SUM(sales) FROM sales_periods GROUP BY demographic,    period
    UNION ALL
    SELECT 'customer_type',  customer_type,  period, SUM(sales) FROM sales_periods GROUP BY customer_type,  period
),

/* put “before” and “after” side‑by‑side, then % change            */
pivot AS (
    SELECT
        a.attribute_type,
        a.attribute_value,
        a.total_sales            AS before_sales,
        b.total_sales            AS after_sales,
        (CAST(b.total_sales AS REAL) - a.total_sales) * 100.0
        / a.total_sales          AS pct_change
    FROM agg a
    JOIN agg b
      ON a.attribute_type = b.attribute_type
     AND a.attribute_value = b.attribute_value
     AND a.period = 'before'
     AND b.period = 'after'
),

/* average % change across all values within each attribute type   */
avg_change AS (
    SELECT
        attribute_type,
        AVG(pct_change) AS avg_pct_change
    FROM pivot
    GROUP BY attribute_type
),

/* pick the attribute type with the greatest negative average drop */
ranked AS (
    SELECT
        attribute_type,
        ROUND(avg_pct_change, 4) AS avg_pct_change,
        RANK() OVER (ORDER BY avg_pct_change ASC) AS rnk
    FROM avg_change
)

SELECT
    attribute_type   AS attribute_with_highest_negative_impact,
    avg_pct_change
FROM ranked
WHERE rnk = 1;