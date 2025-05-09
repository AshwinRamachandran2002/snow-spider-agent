SELECT
     "item_description",
     ROUND((
       (SUM(CASE WHEN EXTRACT(YEAR FROM "date") = 2023 THEN "sale_dollars" ELSE 0 END) -
        SUM(CASE WHEN EXTRACT(YEAR FROM "date") = 2022 THEN "sale_dollars" ELSE 0 END)
       ) / SUM(CASE WHEN EXTRACT(YEAR FROM "date") = 2022 THEN "sale_dollars" ELSE 0 END)
     ) * 100, 4) AS "growth_percentage"
FROM "IOWA_LIQUOR_SALES"."IOWA_LIQUOR_SALES"."SALES"
WHERE EXTRACT(YEAR FROM "date") IN (2022, 2023)
GROUP BY "item_description"
HAVING SUM(CASE WHEN EXTRACT(YEAR FROM "date") = 2022 THEN "sale_dollars" ELSE 0 END) > 0
ORDER BY "growth_percentage" DESC NULLS LAST
LIMIT 5;