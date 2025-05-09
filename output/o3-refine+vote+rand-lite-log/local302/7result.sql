WITH period_sales AS (        -- flag each record as either “before” or “after” the pivot date
    SELECT
        CASE
            WHEN date(week_date) >= date('2020-06-15','-84 days')
             AND date(week_date) <  date('2020-06-15')                THEN 'before'
            WHEN date(week_date) >  date('2020-06-15')
             AND date(week_date) <= date('2020-06-15','+84 days')     THEN 'after'
        END                                               AS period,
        region,
        platform,
        age_band,
        demographic,
        customer_type,
        sales
    FROM cleaned_weekly_sales
    WHERE date(week_date) BETWEEN date('2020-06-15','-84 days')
                              AND     date('2020-06-15','+84 days')
      AND date(week_date) <> date('2020-06-15')
),
-- aggregate before/after sales for every value of every requested attribute type
agg AS (
    SELECT 'region'        AS attribute_type, region        AS attribute_value,
           SUM(CASE WHEN period='before' THEN sales END) AS before_sales,
           SUM(CASE WHEN period='after'  THEN sales END) AS after_sales
    FROM period_sales GROUP BY region

    UNION ALL
    SELECT 'platform', platform,
           SUM(CASE WHEN period='before' THEN sales END),
           SUM(CASE WHEN period='after'  THEN sales END)
    FROM period_sales GROUP BY platform

    UNION ALL
    SELECT 'age_band', age_band,
           SUM(CASE WHEN period='before' THEN sales END),
           SUM(CASE WHEN period='after'  THEN sales END)
    FROM period_sales GROUP BY age_band

    UNION ALL
    SELECT 'demographic', demographic,
           SUM(CASE WHEN period='before' THEN sales END),
           SUM(CASE WHEN period='after'  THEN sales END)
    FROM period_sales GROUP BY demographic

    UNION ALL
    SELECT 'customer_type', customer_type,
           SUM(CASE WHEN period='before' THEN sales END),
           SUM(CASE WHEN period='after'  THEN sales END)
    FROM period_sales GROUP BY customer_type
),
-- percentage change for each attribute value
pct_change AS (
    SELECT
        attribute_type,
        attribute_value,
        (after_sales - before_sales) * 1.0 / NULLIF(before_sales,0) * 100 AS pct_change
    FROM agg
    WHERE before_sales IS NOT NULL
),
-- average percentage change per attribute type
avg_change AS (
    SELECT
        attribute_type,
        AVG(pct_change) AS avg_pct_change
    FROM pct_change
    GROUP BY attribute_type
)
-- final answer: attribute type with the greatest (most negative) average drop in sales
SELECT attribute_type      AS worst_attribute_type,
       avg_pct_change      AS average_percentage_change
FROM   avg_change
ORDER  BY avg_pct_change ASC
LIMIT  1;