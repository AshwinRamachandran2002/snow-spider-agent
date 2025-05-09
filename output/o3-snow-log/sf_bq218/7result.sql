WITH yearly_sales AS (  -- total sales per item for 2022 & 2023
    SELECT
        "item_number",
        "item_description",
        YEAR("date")               AS sales_year,
        SUM("sale_dollars")        AS total_sales
    FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES
    WHERE YEAR("date") IN (2022, 2023)
    GROUP BY
        "item_number",
        "item_description",
        sales_year
),
pivot AS (            -- put the two years on the same row
    SELECT
        "item_number",
        "item_description",
        SUM(CASE WHEN sales_year = 2022 THEN total_sales END) AS sales_2022,
        SUM(CASE WHEN sales_year = 2023 THEN total_sales END) AS sales_2023
    FROM yearly_sales
    GROUP BY
        "item_number",
        "item_description"
),
growth AS (           -- compute YoY growth %
    SELECT
        "item_number",
        "item_description",
        sales_2022,
        sales_2023,
        ROUND( (sales_2023 - sales_2022) / sales_2022 * 100 , 4) AS yoy_growth_pct
    FROM pivot
    WHERE sales_2022 > 0     -- exclude items with no 2022 sales (avoids div-by-zero)
          AND sales_2023 IS NOT NULL
)
SELECT
    "item_number",
    "item_description",
    sales_2022,
    sales_2023,
    yoy_growth_pct
FROM growth
ORDER BY yoy_growth_pct DESC NULLS LAST
LIMIT 5;