SELECT
  ms."product_id",
  ms."mth" AS "month",
  ROUND(
    (
      inv."initial_inventory"
      + COALESCE(pu_cum."qty_purchased_cum", 0)
      - ms_cum."qty_sold_cum"
      + CASE
          WHEN (inv."initial_inventory" + COALESCE(pu_cum."qty_purchased_cum", 0) - ms_cum."qty_sold_cum") < pm."qty_minimum"
          THEN pm."qty_purchase"
          ELSE 0
        END
    ) - pm."qty_minimum"
  , 4) AS "smallest_difference"
FROM "ORACLE_SQL"."ORACLE_SQL"."MONTHLY_SALES" ms
JOIN (
  SELECT "product_id", SUM("qty") AS "initial_inventory"
  FROM "ORACLE_SQL"."ORACLE_SQL"."INVENTORY"
  GROUP BY "product_id"
) inv ON ms."product_id" = inv."product_id"
LEFT JOIN (
  SELECT "product_id", "mth",
    SUM("qty") OVER (PARTITION BY "product_id" ORDER BY "mth") AS "qty_sold_cum"
  FROM "ORACLE_SQL"."ORACLE_SQL"."MONTHLY_SALES"
) ms_cum ON ms."product_id" = ms_cum."product_id" AND ms."mth" = ms_cum."mth"
LEFT JOIN (
  SELECT "product_id", SUBSTR("purchased", 1, 7) AS "mth",
    SUM("qty") OVER (PARTITION BY "product_id" ORDER BY SUBSTR("purchased", 1, 7)) AS "qty_purchased_cum"
  FROM "ORACLE_SQL"."ORACLE_SQL"."PURCHASES"
) pu_cum ON ms."product_id" = pu_cum."product_id" AND ms."mth" = pu_cum."mth"
JOIN "ORACLE_SQL"."ORACLE_SQL"."PRODUCT_MINIMUMS" pm ON ms."product_id" = pm."product_id"
GROUP BY
  ms."product_id",
  ms."mth",
  pm."qty_minimum",
  pm."qty_purchase",
  inv."initial_inventory",
  ms_cum."qty_sold_cum",
  pu_cum."qty_purchased_cum"
ORDER BY "smallest_difference" ASC;