SELECT 
    oi."seller_id" AS "Seller_ID",
    ROUND(SUM(oi."price"), 4) AS "Total_Sales",
    ROUND(AVG(oi."price"), 4) AS "Average_Item_Price",
    ROUND(AVG(orw."review_score"), 4) AS "Average_Review_Score",
    ROUND(
        AVG(
            DATEDIFF(
                'day',
                TRY_TO_TIMESTAMP_NTZ(o."order_approved_at", 'YYYY-MM-DD HH24:MI:SS'),
                TRY_TO_TIMESTAMP_NTZ(oi."shipping_limit_date", 'YYYY-MM-DD HH24:MI:SS')
            )
        ), 4
    ) AS "Packing_Time"
FROM 
    "ELECTRONIC_SALES"."ELECTRONIC_SALES"."ORDER_ITEMS" AS oi
JOIN 
    "ELECTRONIC_SALES"."ELECTRONIC_SALES"."ORDERS" AS o 
    ON oi."order_id" = o."order_id"
JOIN 
    "ELECTRONIC_SALES"."ELECTRONIC_SALES"."ORDER_REVIEWS" AS orw 
    ON o."order_id" = orw."order_id"
GROUP BY 
    oi."seller_id"
HAVING 
    COUNT(oi."order_item_id") > 100
ORDER BY 
    "Total_Sales" DESC NULLS LAST
LIMIT 100;