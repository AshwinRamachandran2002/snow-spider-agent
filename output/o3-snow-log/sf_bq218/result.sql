WITH yearly_sales AS (
    SELECT
        "item_number",
        "item_description",
        EXTRACT(year FROM "date") AS "yr",
        SUM("sale_dollars") AS "total_sales"
    FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES
    WHERE "date" >= '2022-01-01'
      AND "date" <  '2024-01-01'          -- restrict to 2022 and 2023
    GROUP BY
        "item_number",
        "item_description",
        EXTRACT(year FROM "date")
),
pivot_sales AS (
    SELECT
        "item_number",
        "item_description",
        SUM(CASE WHEN "yr" = 2022 THEN "total_sales" END) AS "sales_2022",
        SUM(CASE WHEN "yr" = 2023 THEN "total_sales" END) AS "sales_2023"
    FROM yearly_sales
    GROUP BY
        "item_number",
        "item_description"
),
growth AS (
    SELECT
        "item_number",
        "item_description",
        "sales_2022",
        "sales_2023",
        CASE
            WHEN "sales_2022" > 0 THEN
                 (("sales_2023" - "sales_2022") / "sales_2022") * 100
        END AS "yoy_growth_pct"
    FROM pivot_sales
    WHERE "sales_2022" > 0
      AND "sales_2023" IS NOT NULL
)
SELECT
    "item_number",
    "item_description",
    ROUND("yoy_growth_pct", 4)  AS "yoy_growth_percentage",
    ROUND("sales_2023",     4)  AS "sales_2023",
    ROUND("sales_2022",     4)  AS "sales_2022"
FROM growth
ORDER BY
    "yoy_growth_pct" DESC NULLS LAST
LIMIT 5;