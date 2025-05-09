WITH yearly_sales AS (
    SELECT
        "item_number",
        "item_description",
        YEAR("date")                    AS sales_year,
        SUM("sale_dollars")             AS total_sales
    FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES
    WHERE "date" >= '2022-01-01'              -- only need 2022 & 2023
      AND "date" <  '2024-01-01'
    GROUP BY
        "item_number",
        "item_description",
        YEAR("date")
),
pivot_sales AS (
    SELECT
        "item_number",
        "item_description",
        MAX(CASE WHEN sales_year = 2022 THEN total_sales END) AS sales_2022,
        MAX(CASE WHEN sales_year = 2023 THEN total_sales END) AS sales_2023
    FROM yearly_sales
    GROUP BY
        "item_number",
        "item_description"
),
growth_calc AS (
    SELECT
        "item_number",
        "item_description",
        sales_2022,
        sales_2023,
        (sales_2023 - sales_2022) / sales_2022 * 100 AS growth_pct
    FROM pivot_sales
    WHERE sales_2022 > 0                 -- avoid division by zero
      AND sales_2023 IS NOT NULL
)
SELECT
    "item_number",
    "item_description",
    ROUND(sales_2022, 2)        AS "sales_2022",
    ROUND(sales_2023, 2)        AS "sales_2023",
    ROUND(growth_pct, 4)        AS "growth_percentage"
FROM growth_calc
ORDER BY growth_pct DESC NULLS LAST
LIMIT 5;