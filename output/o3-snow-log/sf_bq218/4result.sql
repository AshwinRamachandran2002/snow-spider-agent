WITH sales_by_year AS (
    SELECT
        "item_number",
        "item_description",
        YEAR("date")                       AS "year",
        SUM("sale_dollars")                AS "total_sales"
    FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES
    WHERE YEAR("date") IN (2022, 2023)
    GROUP BY
        "item_number",
        "item_description",
        YEAR("date")
),

sales_pivot AS (
    SELECT
        "item_number",
        "item_description",
        MAX(CASE WHEN "year" = 2022 THEN "total_sales" END) AS "sales_2022",
        MAX(CASE WHEN "year" = 2023 THEN "total_sales" END) AS "sales_2023"
    FROM sales_by_year
    GROUP BY
        "item_number",
        "item_description"
),

growth_calc AS (
    SELECT
        "item_number",
        "item_description",
        "sales_2022",
        "sales_2023",
        ROUND(
            (("sales_2023" - "sales_2022") / "sales_2022") * 100,
            4
        ) AS "yoy_growth_pct"
    FROM sales_pivot
    WHERE "sales_2022" > 0          -- avoid division by zero
      AND "sales_2023" IS NOT NULL  -- ensure the item was sold in 2023
)

SELECT
    "item_number",
    "item_description",
    "sales_2022",
    "sales_2023",
    "yoy_growth_pct"
FROM growth_calc
ORDER BY "yoy_growth_pct" DESC NULLS LAST
LIMIT 5;