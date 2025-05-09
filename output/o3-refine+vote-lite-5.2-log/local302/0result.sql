WITH period_sales AS (
    /* tag every week as BEFORE (12 wks prior to 15‑Jun‑2020) or AFTER (12 wks following) */
    SELECT
        date("week_date")                                     AS week_dt,
        region,
        platform,
        age_band,
        demographic,
        customer_type,
        sales,
        CASE
            WHEN date("week_date") BETWEEN date('2020-06-15','-84 days')
                                      AND     date('2020-06-14')        THEN 'before'
            WHEN date("week_date") BETWEEN date('2020-06-15')
                                      AND     date('2020-06-15','+83 days') THEN 'after'
        END                                                   AS period
    FROM cleaned_weekly_sales
    WHERE period IS NOT NULL
),                                  /* -------------------------------------------------- */
union_agg AS (
    /* aggregate sales for every attribute value & period */
    SELECT 'region'        AS attribute_type, region        AS attribute_value, period, SUM(sales) AS sales
    FROM period_sales GROUP BY region,        period
    UNION ALL
    SELECT 'platform'      , platform      , period, SUM(sales) FROM period_sales GROUP BY platform      , period
    UNION ALL
    SELECT 'age_band'      , age_band      , period, SUM(sales) FROM period_sales GROUP BY age_band      , period
    UNION ALL
    SELECT 'demographic'   , demographic   , period, SUM(sales) FROM period_sales GROUP BY demographic   , period
    UNION ALL
    SELECT 'customer_type' , customer_type , period, SUM(sales) FROM period_sales GROUP BY customer_type , period
),                                  /* -------------------------------------------------- */
pivot AS (
    /* put BEFORE and AFTER totals side‑by‑side */
    SELECT
        attribute_type,
        attribute_value,
        SUM(CASE WHEN period='before' THEN sales END) AS before_sales,
        SUM(CASE WHEN period='after'  THEN sales END) AS after_sales
    FROM union_agg
    GROUP BY attribute_type, attribute_value
),                                  /* -------------------------------------------------- */
pct_change AS (
    /* percentage change for every attribute value */
    SELECT
        attribute_type,
        attribute_value,
        (after_sales - before_sales) * 1.0 / before_sales * 100.0 AS pct_change
    FROM pivot
    WHERE before_sales > 0
),                                  /* -------------------------------------------------- */
avg_pct AS (
    /* average pct‑change across all values for each attribute type */
    SELECT
        attribute_type,
        AVG(pct_change) AS avg_pct_change
    FROM pct_change
    GROUP BY attribute_type
)
/* attribute type with the largest negative (lowest) average pct‑change */
SELECT
    attribute_type,
    avg_pct_change
FROM avg_pct
ORDER BY avg_pct_change ASC
LIMIT 1;