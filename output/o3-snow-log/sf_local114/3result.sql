WITH ORDERS AS (
    /* Join each web order to its sales-rep and region */
    SELECT
        o."id"                    AS "order_id",
        o."total_amt_usd"         AS "order_value",
        sr."id"                   AS "sales_rep_id",
        sr."name"                 AS "sales_rep_name",
        r."id"                    AS "region_id",
        r."name"                  AS "region_name"
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS."WEB_ORDERS"       o
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS."WEB_ACCOUNTS"     a  ON o."account_id" = a."id"
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS."WEB_SALES_REPS"   sr ON a."sales_rep_id" = sr."id"
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS."WEB_REGION"       r  ON sr."region_id"  = r."id"
),
/* Region-level order count & sales total */
REGION_SUMMARY AS (
    SELECT
        "region_name",
        COUNT("order_id")                      AS "num_orders",
        SUM("order_value")                     AS "total_sales_amount"
    FROM ORDERS
    GROUP BY "region_name"
),
/* Sales-rep totals inside each region */
REP_SALES AS (
    SELECT
        "region_name",
        "sales_rep_id",
        "sales_rep_name",
        SUM("order_value")                     AS "rep_sales_amount"
    FROM ORDERS
    GROUP BY "region_name", "sales_rep_id", "sales_rep_name"
),
/* Identify rep(s) with the highest sales per region (keep ties) */
TOP_REPS AS (
    SELECT
        rs.*,
        MAX("rep_sales_amount") OVER (PARTITION BY "region_name") AS "max_region_sales"
    FROM REP_SALES rs
)
SELECT
    rg."region_name",
    rg."num_orders",
    rg."total_sales_amount",
    tr."sales_rep_name",
    tr."rep_sales_amount"
FROM REGION_SUMMARY rg
JOIN TOP_REPS tr
  ON rg."region_name" = tr."region_name"
WHERE tr."rep_sales_amount" = tr."max_region_sales"
ORDER BY
    rg."region_name" ASC,
    tr."sales_rep_name" ASC;