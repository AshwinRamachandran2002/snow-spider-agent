WITH
products AS (
    SELECT DISTINCT ph."product_id", ph."page_name"
    FROM "shopping_cart_page_hierarchy" AS ph
    WHERE ph."product_id" IS NOT NULL
      AND ph."page_id" NOT IN (1, 2, 12, 13)
),
views AS (
    SELECT ph."product_id", COUNT(*) AS "Views"
    FROM "shopping_cart_events" AS e
    JOIN "shopping_cart_event_identifier" AS ei ON e."event_type" = ei."event_type"
    JOIN "shopping_cart_page_hierarchy" AS ph ON e."page_id" = ph."page_id"
    WHERE ei."event_name" = 'Page View'
      AND ph."product_id" IS NOT NULL
      AND e."page_id" NOT IN (1, 2, 12, 13)
    GROUP BY ph."product_id"
),
add_to_cart AS (
    SELECT
        e."visit_id",
        ph."product_id",
        COUNT(*) AS "Adds_to_Cart"
    FROM
        "shopping_cart_events" AS e
    JOIN
        "shopping_cart_event_identifier" AS ei ON e."event_type" = ei."event_type"
    JOIN
        "shopping_cart_page_hierarchy" AS ph ON e."page_id" = ph."page_id"
    WHERE
        ei."event_name" = 'Add to Cart'
        AND ph."product_id" IS NOT NULL
        AND e."page_id" NOT IN (1, 2, 12, 13)
    GROUP BY
        e."visit_id",
        ph."product_id"
),
purchases AS (
    SELECT DISTINCT
        e."visit_id"
    FROM
        "shopping_cart_events" AS e
    JOIN
        "shopping_cart_event_identifier" AS ei ON e."event_type" = ei."event_type"
    WHERE
        ei."event_name" = 'Purchase'
),
adds_labeled AS (
    SELECT
        a."product_id",
        SUM(CASE WHEN p."visit_id" IS NOT NULL THEN a."Adds_to_Cart" ELSE 0 END) AS "Actual_Purchases",
        SUM(CASE WHEN p."visit_id" IS NULL THEN a."Adds_to_Cart" ELSE 0 END) AS "Left_in_Cart"
    FROM
        add_to_cart a
    LEFT JOIN
        purchases p ON a."visit_id" = p."visit_id"
    GROUP BY
        a."product_id"
),
adds_total AS (
    SELECT
        a."product_id",
        SUM(a."Adds_to_Cart") AS "Adds_to_Cart"
    FROM
        add_to_cart a
    GROUP BY a."product_id"
)
SELECT
    p."product_id" AS "Product_ID",
    p."page_name" AS "Product_Name",
    COALESCE(v."Views", 0) AS "Views",
    COALESCE(at."Adds_to_Cart", 0) AS "Adds_to_Cart",
    COALESCE(al."Left_in_Cart", 0) AS "Left_in_Cart",
    COALESCE(al."Actual_Purchases", 0) AS "Actual_Purchases"
FROM
    products p
LEFT JOIN views v ON p."product_id" = v."product_id"
LEFT JOIN adds_total at ON p."product_id" = at."product_id"
LEFT JOIN adds_labeled al ON p."product_id" = al."product_id"
ORDER BY p."product_id";