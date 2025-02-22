-- Task: Provide a breakdown of how many times each product was viewed and how many times it was added to the shopping cart, excluding products with page_id in (1, 2, 12, 13). Limit the result to 100 rows.

SELECT
    t1."page_id",
    t1."page_name",
    SUM(CASE WHEN t2."event_type" = 1 THEN 1 ELSE 0 END) AS "number of product being viewed",
    SUM(CASE WHEN t2."event_type" = 2 THEN 1 ELSE 0 END) AS "number added to the cart"
FROM
    "BANK_SALES_TRADING"."BANK_SALES_TRADING"."SHOPPING_CART_PAGE_HIERARCHY" AS t1
JOIN
    "BANK_SALES_TRADING"."BANK_SALES_TRADING"."SHOPPING_CART_EVENTS" AS t2
ON
    t1."page_id" = t2."page_id"
WHERE
    t1."product_id" IS NOT NULL
    AND t1."page_id" NOT IN (1, 2, 12, 13)
GROUP BY
    t1."page_id",
    t1."page_name"
LIMIT 100;