WITH yearly_sales AS (
    SELECT
        "item_number",
        "item_description",
        EXTRACT(year FROM "date")            AS "yr",
        SUM("sale_dollars")                  AS "total_sales"
    FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES
    WHERE EXTRACT(year FROM "date") IN (2022, 2023)
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
growth_calc AS (
    SELECT
        "item_number",
        "item_description",
        "sales_2022",
        "sales_2023",
        CASE 
            WHEN "sales_2022" > 0 THEN 
                (("sales_2023" - "sales_2022") / "sales_2022") * 100
        END AS "growth_pct"
    FROM pivot_sales
    WHERE "sales_2022" > 0
      AND "sales_2023" IS NOT NULL
)
SELECT
    "item_number",
    "item_description",
    ROUND("sales_2022", 2)      AS "total_sales_2022",
    ROUND("sales_2023", 2)      AS "total_sales_2023",
    ROUND("growth_pct", 4)      AS "growth_percentage"
FROM growth_calc
ORDER BY "growth_pct" DESC NULLS LAST
LIMIT 5;