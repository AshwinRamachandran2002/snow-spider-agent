WITH sales_percentages AS (
    SELECT t."category", t.year, t.month,
           (t.monthly_volume_sold / m.total_monthly_volume) * 100 AS sales_percentage
    FROM (
        SELECT "category", EXTRACT(YEAR FROM "date") AS year,
               EXTRACT(MONTH FROM "date") AS month,
               SUM("volume_sold_liters") AS monthly_volume_sold
        FROM "IOWA_LIQUOR_SALES"."IOWA_LIQUOR_SALES"."SALES"
        WHERE "date" >= DATE_TRUNC('MONTH', DATEADD(MONTH, -24, CURRENT_DATE))
        GROUP BY "category", year, month
    ) t
    JOIN (
        SELECT EXTRACT(YEAR FROM "date") AS year,
               EXTRACT(MONTH FROM "date") AS month,
               SUM("volume_sold_liters") AS total_monthly_volume
        FROM "IOWA_LIQUOR_SALES"."IOWA_LIQUOR_SALES"."SALES"
        WHERE "date" >= DATE_TRUNC('MONTH', DATEADD(MONTH, -24, CURRENT_DATE))
        GROUP BY year, month
    ) m ON t.year = m.year AND t.month = m.month
    JOIN (
        SELECT "category"
        FROM (
            SELECT "category",
                   AVG((monthly_volume_sold / total_monthly_volume) * 100) AS avg_sales_percentage
            FROM (
                SELECT "category", EXTRACT(YEAR FROM "date") AS year,
                       EXTRACT(MONTH FROM "date") AS month,
                       SUM("volume_sold_liters") AS monthly_volume_sold
                FROM "IOWA_LIQUOR_SALES"."IOWA_LIQUOR_SALES"."SALES"
                WHERE "date" >= DATE_TRUNC('MONTH', DATEADD(MONTH, -24, CURRENT_DATE))
                GROUP BY "category", year, month
            ) t
            JOIN (
                SELECT EXTRACT(YEAR FROM "date") AS year,
                       EXTRACT(MONTH FROM "date") AS month,
                       SUM("volume_sold_liters") AS total_monthly_volume
                FROM "IOWA_LIQUOR_SALES"."IOWA_LIQUOR_SALES"."SALES"
                WHERE "date" >= DATE_TRUNC('MONTH', DATEADD(MONTH, -24, CURRENT_DATE))
                GROUP BY year, month
            ) m ON t.year = m.year AND t.month = m.month
            GROUP BY "category"
            HAVING AVG((monthly_volume_sold / total_monthly_volume) * 100) >= 1
        )
    ) avg_cat ON t."category" = avg_cat."category"
),
category_names AS (
    SELECT DISTINCT "category", "category_name"
    FROM "IOWA_LIQUOR_SALES"."IOWA_LIQUOR_SALES"."SALES"
)
SELECT
    cn1."category_name" AS "Category_1",
    cn2."category_name" AS "Category_2",
    ROUND(CORR(sp1.sales_percentage, sp2.sales_percentage), 4) AS "Lowest_Pearson_Correlation_Coefficient"
FROM sales_percentages sp1
JOIN sales_percentages sp2 ON sp1.year = sp2.year AND sp1.month = sp2.month AND sp1."category" < sp2."category"
JOIN category_names cn1 ON sp1."category" = cn1."category"
JOIN category_names cn2 ON sp2."category" = cn2."category"
GROUP BY cn1."category_name", cn2."category_name"
ORDER BY "Lowest_Pearson_Correlation_Coefficient" ASC
LIMIT 1;