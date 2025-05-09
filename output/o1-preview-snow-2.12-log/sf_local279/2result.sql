WITH months AS (
  SELECT
    DATEADD(month, seq4(), '2019-01-01') AS mth
  FROM table(generator(rowcount => 12))
),
products AS (
  SELECT pm."product_id", pm."qty_minimum", pm."qty_purchase"
  FROM "ORACLE_SQL"."ORACLE_SQL"."PRODUCT_MINIMUMS" pm
),
initial_inventory AS (
  SELECT "product_id", SUM("qty") AS initial_inventory
  FROM "ORACLE_SQL"."ORACLE_SQL"."INVENTORY"
  GROUP BY "product_id"
),
sales_data AS (
  SELECT "product_id", "mth"::date AS mth, SUM("qty") AS sales_quantity
  FROM "ORACLE_SQL"."ORACLE_SQL"."MONTHLY_SALES"
  WHERE "mth" >= '2019-01-01' AND "mth" <= '2019-12-01'
  GROUP BY "product_id", "mth"
),
inventory_simulation AS (
    -- Base case
    SELECT
        p."product_id",
        m.mth,
        ii.initial_inventory AS starting_inventory,
        ii.initial_inventory - COALESCE(sd.sales_quantity, 0) AS ending_inventory,
        COALESCE(sd.sales_quantity, 0) AS sales_quantity,
        p."qty_minimum",
        p."qty_purchase",
        CASE 
          WHEN (ii.initial_inventory - COALESCE(sd.sales_quantity, 0)) < p."qty_minimum" THEN 1 ELSE 0 END AS restocked
    FROM products p
    CROSS JOIN (SELECT mth FROM months WHERE mth = '2019-01-01') m
    LEFT JOIN initial_inventory ii ON p."product_id" = ii."product_id"
    LEFT JOIN sales_data sd ON p."product_id" = sd."product_id" AND sd.mth = m.mth
    UNION ALL
    SELECT
        is_prev."product_id",
        DATEADD(month, 1, is_prev.mth) AS mth,
        is_prev.ending_inventory + (CASE WHEN is_prev.restocked = 1 THEN is_prev."qty_purchase" ELSE 0 END) AS starting_inventory,
        is_prev.ending_inventory + (CASE WHEN is_prev.restocked = 1 THEN is_prev."qty_purchase" ELSE 0 END) - COALESCE(sd.sales_quantity, 0) AS ending_inventory,
        COALESCE(sd.sales_quantity, 0) AS sales_quantity,
        is_prev."qty_minimum",
        is_prev."qty_purchase",
        CASE 
          WHEN (is_prev.ending_inventory + (CASE WHEN is_prev.restocked = 1 THEN is_prev."qty_purchase" ELSE 0 END) - COALESCE(sd.sales_quantity, 0)) < is_prev."qty_minimum"
          THEN 1 ELSE 0 END AS restocked
    FROM inventory_simulation is_prev
    JOIN months m ON DATEADD(month, 1, is_prev.mth) = m.mth
    LEFT JOIN sales_data sd ON is_prev."product_id" = sd."product_id" AND sd.mth = m.mth
    WHERE is_prev.mth < '2019-12-01'
),
inventory_differences AS (
  SELECT
    "product_id",
    mth,
    ending_inventory,
    ABS(ending_inventory - "qty_minimum") AS absolute_difference
  FROM inventory_simulation
)
SELECT
  "product_id",
  TO_CHAR(mth, 'YYYY-MM-DD') AS month,
  ROUND(absolute_difference, 4) AS absolute_difference
FROM (
  SELECT
    "product_id",
    mth,
    absolute_difference,
    ROW_NUMBER() OVER (PARTITION BY "product_id" ORDER BY absolute_difference ASC, mth ASC) AS rn
  FROM inventory_differences
)
WHERE rn = 1
ORDER BY "product_id";