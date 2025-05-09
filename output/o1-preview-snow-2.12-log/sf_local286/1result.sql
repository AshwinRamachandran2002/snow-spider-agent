WITH total_sales_per_seller AS (
    SELECT
        "seller_id",
        COUNT(*) AS "total_products_sold",
        SUM("price") AS "Total_Sales",
        AVG("price") AS "Average_Item_Price"
    FROM
        "ELECTRONIC_SALES"."ELECTRONIC_SALES"."ORDER_ITEMS"
    GROUP BY
        "seller_id"
    HAVING
        COUNT(*) > 100
),
avg_review_score_per_seller AS (
    SELECT
        oi."seller_id",
        AVG(orv."review_score") AS "Average_Review_Score"
    FROM
        "ELECTRONIC_SALES"."ELECTRONIC_SALES"."ORDER_ITEMS" AS oi
        JOIN "ELECTRONIC_SALES"."ELECTRONIC_SALES"."ORDER_REVIEWS" AS orv
            ON oi."order_id" = orv."order_id"
    GROUP BY
        oi."seller_id"
),
avg_packing_time_per_seller AS (
    SELECT
        oi."seller_id",
        AVG(DATEDIFF('hour', 
            TRY_TO_TIMESTAMP(o."order_approved_at", 'YYYY-MM-DD HH24:MI:SS'), 
            TRY_TO_TIMESTAMP(oi."shipping_limit_date", 'YYYY-MM-DD HH24:MI:SS')
        )) AS "Packing_Time"
    FROM
        "ELECTRONIC_SALES"."ELECTRONIC_SALES"."ORDER_ITEMS" AS oi
        JOIN "ELECTRONIC_SALES"."ELECTRONIC_SALES"."ORDERS" AS o
            ON oi."order_id" = o."order_id"
    WHERE
        o."order_approved_at" IS NOT NULL
        AND oi."shipping_limit_date" IS NOT NULL
    GROUP BY
        oi."seller_id"
)
SELECT
    tss."seller_id" AS "Seller_ID",
    ROUND(tss."Total_Sales", 4) AS "Total_Sales",
    ROUND(tss."Average_Item_Price", 4) AS "Average_Item_Price",
    ROUND(arss."Average_Review_Score", 4) AS "Average_Review_Score",
    ROUND(aptps."Packing_Time", 4) AS "Packing_Time"
FROM
    total_sales_per_seller AS tss
    LEFT JOIN avg_review_score_per_seller AS arss
        ON tss."seller_id" = arss."seller_id"
    LEFT JOIN avg_packing_time_per_seller AS aptps
        ON tss."seller_id" = aptps."seller_id"
ORDER BY
    tss."Total_Sales" DESC NULLS LAST;