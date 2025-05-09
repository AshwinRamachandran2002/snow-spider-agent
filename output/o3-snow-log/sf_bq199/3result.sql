WITH txn AS (
    SELECT
        "category_name",
        YEAR("date")                                         AS "year",
        "sale_dollars" / NULLIF("volume_sold_liters", 0)     AS "price_per_liter"
    FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES
    WHERE "date" BETWEEN '2019-01-01' AND '2021-12-31'
      AND "sale_dollars"          IS NOT NULL
      AND "volume_sold_liters"    IS NOT NULL
      AND "volume_sold_liters"   > 0
      AND "category_name"         IS NOT NULL
), avg_price AS (
    SELECT
        "category_name",
        "year",
        AVG("price_per_liter") AS "avg_price_per_liter"
    FROM txn
    GROUP BY "category_name", "year"
), top_cat_2021 AS (
    SELECT "category_name"
    FROM   avg_price
    WHERE  "year" = 2021
    ORDER BY "avg_price_per_liter" DESC NULLS LAST
    LIMIT 10
)
SELECT
    a."category_name",
    a."year",
    ROUND(a."avg_price_per_liter", 4) AS "average_per_liter_retail_price"
FROM   avg_price a
JOIN   top_cat_2021 t
       ON a."category_name" = t."category_name"
WHERE  a."year" IN (2019, 2020, 2021)
ORDER BY a."category_name",
         a."year";