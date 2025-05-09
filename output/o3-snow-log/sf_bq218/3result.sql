WITH yearly_sales AS (
    SELECT
        "item_number",
        "item_description",
        EXTRACT(YEAR FROM "date")                         AS yr,
        SUM("sale_dollars")                              AS total_sales
    FROM "IOWA_LIQUOR_SALES"."IOWA_LIQUOR_SALES"."SALES"
    WHERE EXTRACT(YEAR FROM "date") IN (2022, 2023)
    GROUP BY "item_number", "item_description", yr
),
pivot_sales AS (
    SELECT
        "item_number",
        "item_description",
        SUM(CASE WHEN yr = 2022 THEN total_sales END)    AS sales_2022,
        SUM(CASE WHEN yr = 2023 THEN total_sales END)    AS sales_2023
    FROM yearly_sales
    GROUP BY "item_number", "item_description"
)
SELECT
    "item_number",
    "item_description",
    sales_2022,
    sales_2023,
    ROUND( (sales_2023 - sales_2022) / sales_2022 * 100, 4) AS yoy_growth_pct
FROM pivot_sales
WHERE sales_2022 > 0
  AND sales_2023 IS NOT NULL
ORDER BY yoy_growth_pct DESC NULLS LAST
LIMIT 5;