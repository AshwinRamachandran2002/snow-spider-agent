/*--------------------------------------------------------------
  Recursive monthly-inventory simulation for 2019
----------------------------------------------------------------*/
WITH
/* 1. Minimum / purchase settings */
product_min AS (
    SELECT  "product_id",
            "qty_minimum",
            "qty_purchase"
    FROM ORACLE_SQL.ORACLE_SQL."PRODUCT_MINIMUMS"
),

/* 2. Generate the 12 months of 2019 */
months AS (
    SELECT DATEADD(month, seq4(), '2019-01-01'::date) AS "mth"
    FROM   TABLE(GENERATOR(ROWCOUNT => 12))
),

/* 3. 2019 sales (0 when no record) */
sales_2019 AS (
    SELECT  "product_id",
            TO_DATE("mth")                  AS "mth",
            "qty"
    FROM    ORACLE_SQL.ORACLE_SQL."MONTHLY_SALES"
    WHERE   YEAR(TO_DATE("mth")) = 2019
),

/* 4. Cross-matrix of every (product , month) with sales attached */
base AS (
    SELECT  p."product_id",
            m."mth",
            COALESCE(s."qty", 0)            AS "sales_qty",
            p."qty_minimum",
            p."qty_purchase"
    FROM    product_min  p
    CROSS JOIN months      m
    LEFT  JOIN sales_2019  s
           ON s."product_id" = p."product_id"
          AND s."mth"        = m."mth"
),

/* 5. Recursive inventory calculation */
inv AS (
    /* Anchor row – January 2019 starts with one purchase */
    SELECT  b."product_id",
            b."mth",
            b."qty_minimum",
            b."qty_purchase",
            b."sales_qty",
            b."qty_purchase"                                    AS "begin_inv",
            CASE
                WHEN (b."qty_purchase" - b."sales_qty") < b."qty_minimum"
                     THEN (b."qty_purchase" - b."sales_qty") + b."qty_purchase"
                ELSE      (b."qty_purchase" - b."sales_qty")
            END                                                 AS "end_inv"
    FROM    base b
    WHERE   b."mth" = '2019-01-01'

    UNION ALL

    /* Subsequent months pick up previous month’s ending inventory */
    SELECT  b."product_id",
            b."mth",
            b."qty_minimum",
            b."qty_purchase",
            b."sales_qty",
            i."end_inv"                                         AS "begin_inv",
            CASE
                WHEN (i."end_inv" - b."sales_qty") < b."qty_minimum"
                     THEN (i."end_inv" - b."sales_qty") + b."qty_purchase"
                ELSE      (i."end_inv" - b."sales_qty")
            END                                                 AS "end_inv"
    FROM    inv  i
    JOIN    base b
           ON b."product_id" = i."product_id"
          AND b."mth"        = DATEADD(month, 1, i."mth")
)

/* 6. Pick, per product, the 2019 month whose ending inventory
       is closest to its minimum level */
SELECT  "product_id",
        TO_CHAR("mth",'YYYY-MM')                      AS "best_month",
        ABS("end_inv" - "qty_minimum")                AS "abs_difference"
FROM   (
        SELECT  "product_id",
                "mth",
                "qty_minimum",
                "end_inv",
                ROW_NUMBER() OVER (
                    PARTITION BY "product_id"
                    ORDER BY ABS("end_inv" - "qty_minimum"), "mth"
                ) AS "rn"
        FROM    inv
       )
WHERE   "rn" = 1
ORDER BY "product_id";