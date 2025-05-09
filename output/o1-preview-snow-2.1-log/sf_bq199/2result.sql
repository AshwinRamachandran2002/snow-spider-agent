WITH category_avg_price AS (
    SELECT
        "category_name",
        EXTRACT(YEAR FROM "date") AS "year",
        SUM("sale_dollars") AS total_sales_dollars,
        SUM("volume_sold_liters") AS total_volume_sold_liters,
        ROUND(SUM("sale_dollars") / SUM("volume_sold_liters"), 4) AS avg_price_per_liter
    FROM
        IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES
    WHERE
        "volume_sold_liters" > 0
        AND EXTRACT(YEAR FROM "date") IN (2019, 2020, 2021)
    GROUP BY
        "category_name",
        "year"
),
top_categories_2021 AS (
    SELECT
        "category_name",
        avg_price_per_liter
    FROM
        category_avg_price
    WHERE
        "year" = 2021
    ORDER BY
        avg_price_per_liter DESC NULLS LAST
    LIMIT 10
)
SELECT
    c."category_name" AS "Category_Name",
    MAX(CASE WHEN c."year" = 2019 THEN c.avg_price_per_liter END) AS "Avg_Price_Per_Liter_2019",
    MAX(CASE WHEN c."year" = 2020 THEN c.avg_price_per_liter END) AS "Avg_Price_Per_Liter_2020",
    MAX(CASE WHEN c."year" = 2021 THEN c.avg_price_per_liter END) AS "Avg_Price_Per_Liter_2021"
FROM
    category_avg_price c
    INNER JOIN top_categories_2021 t ON c."category_name" = t."category_name"
GROUP BY
    c."category_name"
ORDER BY
    "Avg_Price_Per_Liter_2021" DESC NULLS LAST
LIMIT 10;