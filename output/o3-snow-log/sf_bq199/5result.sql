WITH prices AS (
    /* Per–transaction price per litre for the three required years */
    SELECT
        "category_name",
        EXTRACT(year FROM "date")                               AS year,
        ("state_bottle_retail" * 1000.0 / NULLIF("bottle_volume_ml",0)) 
                                                               AS price_per_liter
    FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES
    WHERE "date" BETWEEN '2019-01-01' AND '2021-12-31'
      AND "state_bottle_retail" IS NOT NULL
      AND "bottle_volume_ml"    IS NOT NULL
),
top_categories_2021 AS (
    /* Top-10 categories in 2021 by average price per litre */
    SELECT
        "category_name",
        AVG(price_per_liter)            AS avg_price_2021
    FROM prices
    WHERE year = 2021
    GROUP BY "category_name"
    ORDER BY avg_price_2021 DESC NULLS LAST
    LIMIT 10
),
avg_prices AS (
    /* Average price per litre per year for the top categories */
    SELECT
        p."category_name",
        p.year,
        AVG(p.price_per_liter)          AS avg_price_per_liter
    FROM prices p
    JOIN top_categories_2021 t
      ON p."category_name" = t."category_name"
    GROUP BY p."category_name", p.year
)
SELECT
    "category_name",
    ROUND(MAX(CASE WHEN year = 2019 THEN avg_price_per_liter END), 4) AS avg_price_2019,
    ROUND(MAX(CASE WHEN year = 2020 THEN avg_price_per_liter END), 4) AS avg_price_2020,
    ROUND(MAX(CASE WHEN year = 2021 THEN avg_price_per_liter END), 4) AS avg_price_2021
FROM avg_prices
GROUP BY "category_name"
ORDER BY avg_price_2021 DESC NULLS LAST;