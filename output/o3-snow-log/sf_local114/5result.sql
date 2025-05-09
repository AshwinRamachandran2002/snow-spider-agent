/*  Detailed web-sales report by region
    – number of orders,
    – total sales amount,
    – name & sales amount of ALL sales reps that attained the highest
      total sales in their region (ties included)                                     */

WITH orders_with_region AS (
    SELECT
        o."id"                                 AS "order_id",
        o."total_amt_usd"                      AS "order_total",
        o."account_id",
        a."sales_rep_id",
        sr."name"                              AS "sales_rep_name",
        rg."name"                              AS "region_name"
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS."WEB_ORDERS"        o
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS."WEB_ACCOUNTS"      a
          ON o."account_id" = a."id"
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS."WEB_SALES_REPS"    sr
          ON a."sales_rep_id" = sr."id"
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS."WEB_REGION"        rg
          ON sr."region_id" = rg."id"
),

/* overall region-level metrics */
region_summary AS (
    SELECT
        "region_name",
        COUNT("order_id")                         AS "num_orders",
        SUM("order_total")                        AS "region_total_sales"
    FROM orders_with_region
    GROUP BY "region_name"
),

/* sales aggregated per rep per region */
rep_region_sales AS (
    SELECT
        "region_name",
        "sales_rep_id",
        "sales_rep_name",
        SUM("order_total")                        AS "rep_total_sales"
    FROM orders_with_region
    GROUP BY "region_name", "sales_rep_id", "sales_rep_name"
),

/* maximum rep sales per region */
region_max_sales AS (
    SELECT
        "region_name",
        MAX("rep_total_sales")                    AS "max_sales"
    FROM rep_region_sales
    GROUP BY "region_name"
),

/* all reps whose sales equal the regional maximum (handles ties) */
top_reps AS (
    SELECT
        rrs."region_name",
        rrs."sales_rep_name",
        rrs."rep_total_sales"
    FROM rep_region_sales  rrs
    JOIN region_max_sales  rms
          ON  rrs."region_name"   = rms."region_name"
          AND rrs."rep_total_sales" = rms."max_sales"
)

/* final report */
SELECT
    rs."region_name"               AS "Region",
    rs."num_orders"                AS "Number_of_Orders",
    rs."region_total_sales"        AS "Total_Sales_Amount",
    tr."sales_rep_name"            AS "Top_Sales_Rep_Name",
    tr."rep_total_sales"           AS "Top_Sales_Rep_Sales_Amount"
FROM region_summary rs
JOIN top_reps      tr
  ON rs."region_name" = tr."region_name"
ORDER BY
    rs."region_name",
    tr."sales_rep_name";