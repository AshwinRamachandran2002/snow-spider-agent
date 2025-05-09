WITH per_transaction AS (
    /* Calculate the per–liter retail price for every sale in 2019-2021 */
    SELECT
        "category_name"                                            AS category_name,
        "date"                                                     AS sale_date,
        ("state_bottle_retail" * 1000.0) / NULLIF("bottle_volume_ml", 0) AS per_liter_retail_price
    FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES
    WHERE "date" BETWEEN '2019-01-01' AND '2021-12-31'
),
category_year_avg AS (
    /* Average the per–liter prices by category and year */
    SELECT
        category_name,
        EXTRACT(year FROM sale_date)                               AS yr,
        AVG(per_liter_retail_price)                                AS avg_per_liter_price
    FROM per_transaction
    GROUP BY category_name, yr
),
top10_2021 AS (
    /* Pick the 10 categories with the highest average per–liter price in 2021 */
    SELECT
        category_name
    FROM category_year_avg
    WHERE yr = 2021
    QUALIFY RANK() OVER (ORDER BY avg_per_liter_price DESC) <= 10
)
SELECT
    c.category_name,
    ROUND(AVG(CASE WHEN c.yr = 2019 THEN c.avg_per_liter_price END), 4) AS avg_price_2019,
    ROUND(AVG(CASE WHEN c.yr = 2020 THEN c.avg_per_liter_price END), 4) AS avg_price_2020,
    ROUND(AVG(CASE WHEN c.yr = 2021 THEN c.avg_per_liter_price END), 4) AS avg_price_2021
FROM category_year_avg c
JOIN top10_2021 t
  ON c.category_name = t.category_name
GROUP BY c.category_name
ORDER BY avg_price_2021 DESC NULLS LAST;