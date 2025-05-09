WITH base AS (
    /* 24-week window centred on 15-Jun-2020 */
    SELECT week_date,
           sales,
           region,
           platform,
           age_band,
           demographic,
           customer_type
    FROM cleaned_weekly_sales
    WHERE week_date BETWEEN '2020-03-23' AND '2020-09-07'
),
/* total sales before vs after 15-Jun-2020 for every value of each attribute type */
totals AS (
    SELECT region                AS attribute_value,
           'region'              AS attribute_type,
           SUM(CASE WHEN week_date < '2020-06-15'  THEN sales END) AS sales_before,
           SUM(CASE WHEN week_date > '2020-06-15'  THEN sales END) AS sales_after
    FROM base GROUP BY region

    UNION ALL
    SELECT platform, 'platform',
           SUM(CASE WHEN week_date < '2020-06-15'  THEN sales END),
           SUM(CASE WHEN week_date > '2020-06-15'  THEN sales END)
    FROM base GROUP BY platform

    UNION ALL
    SELECT age_band, 'age_band',
           SUM(CASE WHEN week_date < '2020-06-15'  THEN sales END),
           SUM(CASE WHEN week_date > '2020-06-15'  THEN sales END)
    FROM base GROUP BY age_band

    UNION ALL
    SELECT demographic, 'demographic',
           SUM(CASE WHEN week_date < '2020-06-15'  THEN sales END),
           SUM(CASE WHEN week_date > '2020-06-15'  THEN sales END)
    FROM base GROUP BY demographic

    UNION ALL
    SELECT customer_type, 'customer_type',
           SUM(CASE WHEN week_date < '2020-06-15'  THEN sales END),
           SUM(CASE WHEN week_date > '2020-06-15'  THEN sales END)
    FROM base GROUP BY customer_type
),
/* % change per individual attribute value */
pct_change AS (
    SELECT attribute_type,
           attribute_value,
           (CAST(sales_after - sales_before AS REAL) / sales_before) * 100.0 AS pct_change
    FROM totals
    WHERE sales_before <> 0            -- protect against divide-by-zero
),
/* average % change for each attribute type */
avg_pct AS (
    SELECT attribute_type,
           ROUND(AVG(pct_change), 4) AS avg_pct_change
    FROM pct_change
    GROUP BY attribute_type
)
/* attribute type with the greatest negative impact */
SELECT attribute_type,
       avg_pct_change
FROM   avg_pct
ORDER  BY avg_pct_change            -- most negative first
LIMIT  1;