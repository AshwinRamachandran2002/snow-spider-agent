WITH region_totals AS (
    SELECT
        r."id" AS region_id,
        r."name" AS Region,
        COUNT(o."id") AS Number_of_Orders,
        SUM(o."total_amt_usd") AS Total_Sales_Amount
    FROM
        "web_orders" AS o
    JOIN "web_accounts" AS a ON o."account_id" = a."id"
    JOIN "web_sales_reps" AS s ON a."sales_rep_id" = s."id"
    JOIN "web_region" AS r ON s."region_id" = r."id"
    GROUP BY r."id", r."name"
),
top_sales_reps AS (
    SELECT
        region_id,
        region_name,
        sales_rep_name,
        total_sales_amount
    FROM (
        SELECT
            r."id" AS region_id,
            r."name" AS region_name,
            s."name" AS sales_rep_name,
            SUM(o."total_amt_usd") AS total_sales_amount,
            ROW_NUMBER() OVER (PARTITION BY r."id" ORDER BY SUM(o."total_amt_usd") DESC) AS sales_rank
        FROM
            "web_orders" AS o
        JOIN "web_accounts" AS a ON o."account_id" = a."id"
        JOIN "web_sales_reps" AS s ON a."sales_rep_id" = s."id"
        JOIN "web_region" AS r ON s."region_id" = r."id"
        GROUP BY r."id", s."id", s."name"
    )
    WHERE sales_rank = 1
)
SELECT
    rt.Region,
    rt.Number_of_Orders,
    ROUND(rt.Total_Sales_Amount, 4) AS Total_Sales_Amount,
    tsr.sales_rep_name AS Top_Sales_Rep_Name,
    ROUND(tsr.total_sales_amount, 4) AS Top_Sales_Rep_Sales_Amount
FROM
    region_totals rt
JOIN
    top_sales_reps tsr ON rt.region_id = tsr.region_id;