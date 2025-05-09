WITH period_window AS (
    /* Flag each row as belonging to the 12‑weeks BEFORE or AFTER 15‑Jun‑2020 */
    SELECT *,
           CASE
               WHEN "week_date" BETWEEN date('2020-06-15','-84 days')
                                  AND '2020-06-15'
               THEN 'before'
               WHEN "week_date" BETWEEN date('2020-06-15','+7 days')
                                  AND date('2020-06-15','+84 days')
               THEN 'after'
           END AS period_flag
    FROM cleaned_weekly_sales
    WHERE "week_date" BETWEEN date('2020-06-15','-84 days')
                         AND date('2020-06-15','+84 days')
), unpivot AS (
    /* Bring all attribute types into one unioned set                */
    SELECT 'region'        AS attribute_type, region        AS attribute_value, period_flag, SUM(sales) AS sales
    FROM period_window GROUP BY region,        period_flag
    UNION ALL
    SELECT 'platform',       platform,        period_flag, SUM(sales)
    FROM period_window GROUP BY platform,      period_flag
    UNION ALL
    SELECT 'age_band',       age_band,        period_flag, SUM(sales)
    FROM period_window GROUP BY age_band,      period_flag
    UNION ALL
    SELECT 'demographic',    demographic,     period_flag, SUM(sales)
    FROM period_window GROUP BY demographic,   period_flag
    UNION ALL
    SELECT 'customer_type',  customer_type,   period_flag, SUM(sales)
    FROM period_window GROUP BY customer_type, period_flag
), pivot AS (
    /* Put BEFORE and AFTER totals on the same row */
    SELECT attribute_type,
           attribute_value,
           SUM(CASE WHEN period_flag='before' THEN sales END) AS before_sales,
           SUM(CASE WHEN period_flag='after'  THEN sales END) AS after_sales
    FROM unpivot
    GROUP BY attribute_type, attribute_value
), pct_change AS (
    /* % change for every individual attribute value */
    SELECT attribute_type,
           attribute_value,
           100.0 * (after_sales - before_sales) / before_sales AS pct_change
    FROM pivot
    WHERE before_sales > 0
), avg_pct AS (
    /* Average % change for each attribute TYPE */
    SELECT attribute_type,
           ROUND(AVG(pct_change), 2) AS avg_pct_change
    FROM pct_change
    GROUP BY attribute_type
)
SELECT attribute_type        AS attribute_type_with_highest_negative_impact,
       avg_pct_change        AS average_percentage_change
FROM   avg_pct
ORDER BY avg_pct_change       -- most negative first
LIMIT 1;