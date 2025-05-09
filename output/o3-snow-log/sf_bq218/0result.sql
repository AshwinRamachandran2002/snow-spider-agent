WITH yearly_sales AS (
    SELECT
        "item_number",
        "item_description",
        SUM(CASE WHEN EXTRACT(year FROM "date") = 2022 THEN "sale_dollars" END) AS revenue_2022,
        SUM(CASE WHEN EXTRACT(year FROM "date") = 2023 THEN "sale_dollars" END) AS revenue_2023
    FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES."SALES"
    WHERE EXTRACT(year FROM "date") IN (2022, 2023)
    GROUP BY
        "item_number",
        "item_description"
),
growth_calc AS (
    SELECT
        "item_number",
        "item_description",
        revenue_2022,
        revenue_2023,
        ROUND(
            CASE
                WHEN revenue_2022 > 0 THEN (revenue_2023 - revenue_2022) / revenue_2022 * 100
                ELSE NULL
            END
        , 4) AS yoy_growth_pct
    FROM yearly_sales
)
SELECT
    "item_number",
    "item_description",
    revenue_2022,
    revenue_2023,
    yoy_growth_pct
FROM growth_calc
WHERE revenue_2023 IS NOT NULL
ORDER BY yoy_growth_pct DESC NULLS LAST
LIMIT 5;