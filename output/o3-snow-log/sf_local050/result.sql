WITH sales_france AS (
    SELECT
        s."prod_id",
        t."calendar_year"  AS "yr",
        t."calendar_month_number" AS "mnth",
        SUM( s."amount_sold" * COALESCE(cur."to_us",1) ) AS "sales_usd"
    FROM "COMPLEX_ORACLE"."COMPLEX_ORACLE"."SALES"        s
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CUSTOMERS"    cu   ON s."cust_id"   = cu."cust_id"
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."COUNTRIES"    co   ON cu."country_id" = co."country_id"
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CHANNELS"     ch   ON s."channel_id" = ch."channel_id"
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."PROMOTIONS"   pr   ON s."promo_id"   = pr."promo_id"
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."TIMES"        t    ON s."time_id"   = t."time_id"
    LEFT JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CURRENCY" cur
           ON  cur."country" = co."country_name"
           AND cur."year"    = t."calendar_year"
           AND cur."month"   = t."calendar_month_number"
    WHERE   co."country_name" = 'France'
        AND t."calendar_year" IN (2019,2020)
        AND ch."channel_total_id" = 1
        AND pr."promo_total_id"   = 1
    GROUP BY
        s."prod_id",
        t."calendar_year",
        t."calendar_month_number"
),
pivot_sales AS (
    SELECT
        "prod_id",
        "mnth",
        SUM( CASE WHEN "yr" = 2019 THEN "sales_usd" END ) AS "sales_2019",
        SUM( CASE WHEN "yr" = 2020 THEN "sales_usd" END ) AS "sales_2020"
    FROM sales_france
    GROUP BY "prod_id","mnth"
),
projected_2021 AS (
    SELECT
        "prod_id",
        "mnth",
        CASE
            WHEN "sales_2019" IS NOT NULL
             AND "sales_2019" <> 0
             AND "sales_2020" IS NOT NULL
            THEN ( ("sales_2020" - "sales_2019") / "sales_2019" ) * "sales_2020" + "sales_2020"
            ELSE NULL
        END AS "proj_2021"
    FROM pivot_sales
),
monthly_avg AS (
    SELECT
        "mnth",
        AVG("proj_2021") AS "avg_monthly_proj_2021"
    FROM projected_2021
    WHERE "proj_2021" IS NOT NULL
    GROUP BY "mnth"
)
SELECT
    MEDIAN("avg_monthly_proj_2021") AS "median_avg_monthly_proj_usd_2021"
FROM monthly_avg;