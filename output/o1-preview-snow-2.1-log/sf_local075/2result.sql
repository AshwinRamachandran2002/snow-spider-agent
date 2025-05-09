WITH purchase_visits AS (
    SELECT DISTINCT "visit_id"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."SHOPPING_CART_EVENTS"
    WHERE "event_type" = 3
)
SELECT
    ph."product_id",
    COUNT(CASE WHEN e."event_type" = 1 THEN 1 END) AS "views",
    COUNT(CASE WHEN e."event_type" = 2 THEN 1 END) AS "adds_to_cart",
    COUNT(CASE WHEN e."event_type" = 2 AND e."visit_id" NOT IN (SELECT "visit_id" FROM purchase_visits) THEN 1 END) AS "left_in_cart",
    COUNT(CASE WHEN e."event_type" = 2 AND e."visit_id" IN (SELECT "visit_id" FROM purchase_visits) THEN 1 END) AS "purchases"
FROM
    BANK_SALES_TRADING.BANK_SALES_TRADING."SHOPPING_CART_EVENTS" e
JOIN
    BANK_SALES_TRADING.BANK_SALES_TRADING."SHOPPING_CART_PAGE_HIERARCHY" ph
    ON e."page_id" = ph."page_id"
WHERE
    ph."product_id" IS NOT NULL
    AND e."page_id" NOT IN (1, 2, 12, 13)
GROUP BY
    ph."product_id";