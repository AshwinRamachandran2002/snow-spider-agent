WITH period_sales AS (
    /* total sales for each attribute value in the 12‑week windows   */
    SELECT
        region,
        platform,
        age_band,
        demographic,
        customer_type,

        /* 12 weeks BEFORE 15‑Jun‑2020: 23‑Mar‑2020  → 14‑Jun‑2020   */
        SUM(
            CASE 
                WHEN date(week_date) BETWEEN date('2020-06-15','-84 days')
                                        AND date('2020-06-14')
                THEN sales ELSE 0
            END
        ) AS pre_sales,

        /* 12 weeks AFTER 15‑Jun‑2020: 15‑Jun‑2020  → 06‑Sep‑2020    */
        SUM(
            CASE
                WHEN date(week_date) BETWEEN date('2020-06-15')
                                        AND date('2020-06-15','+83 days')
                THEN sales ELSE 0
            END
        ) AS post_sales
    FROM cleaned_weekly_sales
    WHERE date(week_date) BETWEEN date('2020-06-15','-84 days')
                             AND date('2020-06-15','+83 days')
    GROUP BY
        region,
        platform,
        age_band,
        demographic,
        customer_type
),

/* percentage change for every individual attribute value           */
percent_changes AS (
    SELECT 'region'       AS attribute_type, region        AS attribute_value,
           100.0 * (post_sales - pre_sales) / pre_sales    AS pct_change
    FROM period_sales WHERE pre_sales <> 0

    UNION ALL
    SELECT 'platform',    platform,
           100.0 * (post_sales - pre_sales) / pre_sales
    FROM period_sales WHERE pre_sales <> 0

    UNION ALL
    SELECT 'age_band',    age_band,
           100.0 * (post_sales - pre_sales) / pre_sales
    FROM period_sales WHERE pre_sales <> 0

    UNION ALL
    SELECT 'demographic', demographic,
           100.0 * (post_sales - pre_sales) / pre_sales
    FROM period_sales WHERE pre_sales <> 0

    UNION ALL
    SELECT 'customer_type', customer_type,
           100.0 * (post_sales - pre_sales) / pre_sales
    FROM period_sales WHERE pre_sales <> 0
),

/* average % change across all values of each attribute type         */
avg_pct_change AS (
    SELECT
        attribute_type,
        AVG(pct_change) AS avg_pct_change
    FROM percent_changes
    GROUP BY attribute_type
)

/* attribute type with the largest negative (lowest) average change  */
SELECT attribute_type      AS worst_attribute_type,
       avg_pct_change      AS average_pct_change
FROM   avg_pct_change
ORDER  BY avg_pct_change ASC
LIMIT 1;