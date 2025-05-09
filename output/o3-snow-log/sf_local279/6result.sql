/*---------------------------------------------------------------
  Recursive monthly-inventory simulation (Dec-2018 start)
  – Restock by “qty_purchase” whenever end-inventory < qty_minimum
  – Find, for every product, the 2019 month whose end-inventory
    is closest to (i.e. smallest absolute difference from)
    its minimum level
----------------------------------------------------------------*/
WITH
/* 1.  Products that have defined minimum / purchase lots */
PRODUCT_MIN AS (
    SELECT  "product_id"      ::NUMBER        AS product_id ,
            "qty_minimum"     ::FLOAT         AS qty_minimum ,
            "qty_purchase"    ::FLOAT         AS qty_purchase
    FROM    ORACLE_SQL.ORACLE_SQL."PRODUCT_MINIMUMS"
),

/* 2.  Month calendar: 2018-12-01 … 2019-12-01 (inclusive)      */
CAL_MONTHS AS (
    SELECT  DATEADD(month , SEQ4() , '2018-12-01'::DATE) AS mth
    FROM    TABLE(GENERATOR(ROWCOUNT => 13))                              -- 0-12
),

/* 3.  Sales per product / month (missing rows → 0)            */
SALES_RAW AS (
    SELECT  "product_id"::NUMBER                    AS product_id ,
            TO_DATE("mth")                         AS mth ,
            "qty"::FLOAT                           AS qty
    FROM    ORACLE_SQL.ORACLE_SQL."MONTHLY_SALES"
    WHERE   TO_DATE("mth") BETWEEN '2018-12-01' AND '2019-12-31'
),
SALES_FULL AS (
    SELECT      p.product_id ,
                cm.mth ,
                COALESCE(sr.qty , 0)               AS sales_qty ,
                p.qty_minimum ,
                p.qty_purchase
    FROM        PRODUCT_MIN p
    CROSS JOIN  CAL_MONTHS  cm
    LEFT JOIN   SALES_RAW   sr
           ON   sr.product_id = p.product_id
          AND   sr.mth        = cm.mth
),

/* 4.  Seed row : start inventory (assume one purchase lot)     */
SEED AS (
    SELECT  product_id ,
            mth ,
            sales_qty ,
            qty_minimum ,
            qty_purchase ,
            /* initial end-inventory */
            qty_purchase                       AS inventory_end
    FROM    SALES_FULL
    WHERE   mth = '2018-12-01'
),

/* 5.  Recursive month-by-month inventory calculation           */
INV AS (
    SELECT  *  FROM SEED
    UNION ALL
    SELECT  sf.product_id ,
            sf.mth ,
            sf.sales_qty ,
            sf.qty_minimum ,
            sf.qty_purchase ,
            /* restock when needed */
            CASE
                WHEN (i.inventory_end - sf.sales_qty) < sf.qty_minimum
                THEN (i.inventory_end - sf.sales_qty) + sf.qty_purchase
                ELSE (i.inventory_end - sf.sales_qty)
            END                                   AS inventory_end
    FROM    INV i
    JOIN    SALES_FULL sf
           ON sf.product_id = i.product_id
          AND sf.mth        = DATEADD(month , 1 , i.mth)
),

/* 6.  Absolute diff between end-inventory and minimum          */
DIFFS AS (
    SELECT  product_id ,
            mth ,
            ABS(inventory_end - qty_minimum)      AS diff
    FROM    INV
    WHERE   mth BETWEEN '2019-01-01' AND '2019-12-31'
),

/* 7.  Pick the month with the smallest diff (ties → earliest)  */
RANKED AS (
    SELECT  * ,
            ROW_NUMBER() OVER (PARTITION BY product_id
                               ORDER BY diff ASC , mth ASC) AS rn
    FROM    DIFFS
)

SELECT  product_id ,
        TO_CHAR(mth , 'YYYY-MM-DD')  AS month ,
        diff
FROM    RANKED
WHERE   rn = 1
ORDER BY product_id;