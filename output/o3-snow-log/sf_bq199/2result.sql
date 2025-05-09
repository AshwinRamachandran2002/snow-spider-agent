WITH per_txn AS (
    /* Per-transaction per-liter retail price */
    SELECT
        "category_name",
        DATE_PART('year', "date")              AS yr,
        "state_bottle_retail" / ("bottle_volume_ml" / 1000.0)  AS price_per_liter
    FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES."SALES"
    WHERE "state_bottle_retail" IS NOT NULL
      AND "bottle_volume_ml"   IS NOT NULL
      AND "bottle_volume_ml"  > 0
),
cat_avg AS (
    /* Average per-liter retail price per category and year (2019-2021) */
    SELECT
        "category_name",
        yr,
        AVG(price_per_liter) AS avg_price_per_liter
    FROM per_txn
    WHERE yr IN (2019, 2020, 2021)
    GROUP BY "category_name", yr
),
top10_2021 AS (
    /* Top 10 categories by 2021 average per-liter retail price */
    SELECT
        "category_name"
    FROM cat_avg
    WHERE yr = 2021
    ORDER BY avg_price_per_liter DESC NULLS LAST
    LIMIT 10
)
/* Final output: average per-liter retail prices for 2019-2021 in top 2021 categories */
SELECT
    t."category_name",
    ROUND(MAX(CASE WHEN c.yr = 2019 THEN c.avg_price_per_liter END), 4) AS avg_price_per_liter_2019,
    ROUND(MAX(CASE WHEN c.yr = 2020 THEN c.avg_price_per_liter END), 4) AS avg_price_per_liter_2020,
    ROUND(MAX(CASE WHEN c.yr = 2021 THEN c.avg_price_per_liter END), 4) AS avg_price_per_liter_2021
FROM top10_2021 t
JOIN cat_avg c
  ON t."category_name" = c."category_name"
GROUP BY t."category_name"
ORDER BY avg_price_per_liter_2021 DESC NULLS LAST;