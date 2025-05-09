SELECT
    p."product_id" AS "Product_ID",
    p."page_name" AS "Product_Name",
    SUM(CASE WHEN e."event_type" = 1 THEN 1 ELSE 0 END) AS "Views",
    SUM(CASE WHEN e."event_type" = 2 THEN 1 ELSE 0 END) AS "Adds_to_Cart",
    (
        SUM(CASE WHEN e."event_type" = 2 THEN 1 ELSE 0 END) -
        SUM(CASE WHEN e."event_type" = 2 AND e."cookie_id" IN (
            SELECT DISTINCT "cookie_id"
            FROM "shopping_cart_events"
            WHERE "event_type" = 3
        ) THEN 1 ELSE 0 END)
    ) AS "Left_in_Cart",
    SUM(CASE WHEN e."event_type" = 2 AND e."cookie_id" IN (
        SELECT DISTINCT "cookie_id"
        FROM "shopping_cart_events"
        WHERE "event_type" = 3
    ) THEN 1 ELSE 0 END) AS "Actual_Purchases"
FROM
    "shopping_cart_events" e
JOIN
    "shopping_cart_page_hierarchy" p ON e."page_id" = p."page_id"
WHERE
    e."event_type" IN (1, 2)
    AND e."page_id" NOT IN (1, 2, 12, 13)
GROUP BY
    p."product_id",
    p."page_name"
ORDER BY
    p."product_id";