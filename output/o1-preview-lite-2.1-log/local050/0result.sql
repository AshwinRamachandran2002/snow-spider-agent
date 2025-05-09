WITH
    monthly_sales AS (
        SELECT
            ("proj"."projected_sales" * "cur"."to_us") AS "projected_sales_usd"
        FROM (
            SELECT
                "t"."calendar_month_number",
                AVG("s"."amount_sold") AS "projected_sales"
            FROM "sales" AS "s"
            JOIN "customers" AS "c" ON "s"."cust_id" = "c"."cust_id"
            JOIN "countries" AS "co" ON "c"."country_id" = "co"."country_id"
            JOIN "times" AS "t" ON "s"."time_id" = "t"."time_id"
            WHERE
                "co"."country_name" = 'France' AND
                "t"."calendar_year" IN (2019, 2020)
            GROUP BY "t"."calendar_month_number"
        ) AS "proj"
        JOIN "currency" AS "cur" ON (
            "cur"."country" = 'France' AND
            "cur"."year" = 2021 AND
            "cur"."month" = "proj"."calendar_month_number"
        )
    ),
    ordered_sales AS (
        SELECT "projected_sales_usd"
        FROM monthly_sales
        ORDER BY "projected_sales_usd"
    )
SELECT
    AVG("projected_sales_usd") AS "Median_average_monthly_projected_sales_USD"
FROM (
    SELECT "projected_sales_usd"
    FROM ordered_sales
    LIMIT 2 OFFSET 5
);