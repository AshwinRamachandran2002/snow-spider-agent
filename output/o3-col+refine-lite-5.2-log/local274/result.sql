SELECT p."name" AS "product_name",
       avg_q."avg_units_picked"
FROM (
        SELECT "product_id",
               AVG("qty") AS "avg_units_picked"
        FROM "picking_line"
        WHERE "order_id" = 421
        GROUP BY "product_id"
     ) AS avg_q
JOIN "products" AS p
  ON p."id" = avg_q."product_id";