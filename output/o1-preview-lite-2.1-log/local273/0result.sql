SELECT p."name" AS "Product_Name",
       AVG(pl."qty" * 1.0 / ol."qty") AS "Average_Pick_Percentage"
FROM "orderlines" ol
JOIN "picking_line" pl ON ol."order_id" = pl."order_id" 
                      AND ol."product_id" = pl."product_id"
JOIN "products" p ON ol."product_id" = p."id"
GROUP BY p."name";