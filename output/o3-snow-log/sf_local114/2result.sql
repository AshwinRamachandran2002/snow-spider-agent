WITH "REP_SALES" AS (
    SELECT
        WR."name"                                    AS "region_name",
        SR."id"                                      AS "sales_rep_id",
        SR."name"                                    AS "sales_rep_name",
        COUNT(WO."id")                               AS "orders_count",
        SUM(WO."total_amt_usd")                      AS "sales_amount"
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS."WEB_ORDERS"        WO
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS."WEB_ACCOUNTS"      WA ON WO."account_id" = WA."id"
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS."WEB_SALES_REPS"    SR ON WA."sales_rep_id" = SR."id"
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS."WEB_REGION"        WR ON SR."region_id"  = WR."id"
    GROUP BY
        WR."name",
        SR."id",
        SR."name"
),
"REGION_TOTAL" AS (
    SELECT
        "region_name",
        SUM("orders_count")      AS "total_orders",
        SUM("sales_amount")      AS "total_sales_amount"
    FROM "REP_SALES"
    GROUP BY "region_name"
),
"REGION_MAX_REP_SALES" AS (
    SELECT
        "region_name",
        MAX("sales_amount")      AS "max_sales_amount"
    FROM "REP_SALES"
    GROUP BY "region_name"
),
"TOP_REPS" AS (
    SELECT
        RS."region_name",
        RS."sales_rep_name",
        RS."sales_amount"
    FROM "REP_SALES" RS
    JOIN "REGION_MAX_REP_SALES" RM
      ON RS."region_name" = RM."region_name"
     AND RS."sales_amount" = RM."max_sales_amount"
)
SELECT
    RT."region_name",
    RT."total_orders"              AS "number_of_orders",
    RT."total_sales_amount",
    TR."sales_rep_name",
    TR."sales_amount"              AS "sales_rep_total_sales_amount"
FROM "REGION_TOTAL" RT
JOIN "TOP_REPS"   TR
  ON RT."region_name" = TR."region_name"
ORDER BY
    RT."total_sales_amount" DESC NULLS LAST,
    RT."region_name",
    TR."sales_rep_name";