WITH sales_by_item AS (
    SELECT
        "item_number",
        MAX("item_description")                                             AS "item_description",
        SUM(CASE WHEN EXTRACT(year FROM "date") = 2022 
                 THEN "sale_dollars" END)                                   AS "sales_2022",
        SUM(CASE WHEN EXTRACT(year FROM "date") = 2023 
                 THEN "sale_dollars" END)                                   AS "sales_2023"
    FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES
    WHERE EXTRACT(year FROM "date") IN (2022, 2023)
    GROUP BY "item_number"
), growth AS (
    SELECT
        "item_number",
        "item_description",
        "sales_2022",
        "sales_2023",
        ROUND( ( "sales_2023" - "sales_2022") / NULLIF("sales_2022", 0) * 100 , 4) 
                                                                          AS "yoy_growth_pct"
    FROM sales_by_item
    WHERE "sales_2022" IS NOT NULL 
      AND "sales_2023" IS NOT NULL 
      AND "sales_2022" <> 0
)
SELECT
    "item_number",
    "item_description",
    "sales_2022",
    "sales_2023",
    "yoy_growth_pct"
FROM growth
ORDER BY "yoy_growth_pct" DESC NULLS LAST
LIMIT 5;