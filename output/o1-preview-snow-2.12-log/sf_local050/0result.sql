WITH monthly_sales AS (
    SELECT
        t."calendar_month_number" AS "month_number",
        SUM(CASE WHEN t."calendar_year" = 2019 THEN s."amount_sold" ELSE 0 END) AS "sales_2019",
        SUM(CASE WHEN t."calendar_year" = 2020 THEN s."amount_sold" ELSE 0 END) AS "sales_2020"
    FROM "COMPLEX_ORACLE"."COMPLEX_ORACLE"."SALES" s
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CUSTOMERS" c ON s."cust_id" = c."cust_id"
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."COUNTRIES" co ON c."country_id" = co."country_id"
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."TIMES" t ON s."time_id" = t."time_id"
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."PROMOTIONS" p ON s."promo_id" = p."promo_id"
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CHANNELS" ch ON s."channel_id" = ch."channel_id"
    WHERE co."country_name" = 'France' 
      AND t."calendar_year" IN (2019, 2020)
      AND p."promo_total_id" = 1 
      AND ch."channel_total_id" = 1
    GROUP BY t."calendar_month_number"
), projected_sales AS (
  SELECT
    m."month_number",
    CASE 
      WHEN m."sales_2019" = 0 THEN m."sales_2020"
      ELSE m."sales_2020" * (1 + ((m."sales_2020" - m."sales_2019") / NULLIF(m."sales_2019",0))) 
    END AS "projected_sales"
  FROM monthly_sales m
), projected_sales_usd AS (
  SELECT
    ps."month_number",
    ps."projected_sales" * COALESCE(cu."to_us", 1.0) AS "projected_sales_usd"
  FROM projected_sales ps
  LEFT JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CURRENCY" cu 
    ON cu."country" = 'France' 
    AND cu."year" = 2021 
    AND cu."month" = ps."month_number"
)
SELECT
  MEDIAN("projected_sales_usd") AS "Median_Average_Monthly_Sales_USD"
FROM projected_sales_usd;