WITH sales_rep_sales AS (
    SELECT
        r."name" AS "region_name",
        s."name" AS "sales_rep_name",
        SUM(o."total_amt_usd") AS "sales_rep_total_sales"
    FROM
        "web_orders" AS o
        JOIN "web_accounts" AS a ON o."account_id" = a."id"
        JOIN "web_sales_reps" AS s ON a."sales_rep_id" = s."id"
        JOIN "web_region" AS r ON s."region_id" = r."id"
    GROUP BY
        r."name",
        s."name"
),
region_totals AS (
    SELECT
        r."name" AS "region_name",
        COUNT(o."id") AS "number_of_orders",
        SUM(o."total_amt_usd") AS "total_sales_amount"
    FROM
        "web_orders" AS o
        JOIN "web_accounts" AS a ON o."account_id" = a."id"
        JOIN "web_sales_reps" AS s ON a."sales_rep_id" = s."id"
        JOIN "web_region" AS r ON s."region_id" = r."id"
    GROUP BY
        r."name"
),
sales_rep_ranked AS (
    SELECT
        srs.*,
        RANK() OVER (
            PARTITION BY srs."region_name"
            ORDER BY srs."sales_rep_total_sales" DESC
        ) AS "sales_rank"
    FROM
        sales_rep_sales srs
)
SELECT
    rt."region_name" AS "Region",
    rt."number_of_orders" AS "Number_of_Orders",
    ROUND(rt."total_sales_amount", 4) AS "Total_Sales_Amount",
    srr."sales_rep_name" AS "Top_Sales_Rep_Name",
    ROUND(srr."sales_rep_total_sales", 4) AS "Top_Sales_Rep_Sales_Amount"
FROM
    region_totals rt
    JOIN (
        SELECT
            "region_name",
            "sales_rep_name",
            "sales_rep_total_sales"
        FROM
            sales_rep_ranked
        WHERE
            "sales_rank" = 1
    ) srr ON rt."region_name" = srr."region_name";