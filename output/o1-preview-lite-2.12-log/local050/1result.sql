WITH projected_sales AS
(
    SELECT
        t2020."calendar_month_number",
        t2020."average_amount_sold" AS "average_2020",
        t2019."average_amount_sold" AS "average_2019",
        ((t2020."average_amount_sold" - t2019."average_amount_sold") / t2019."average_amount_sold") AS "growth_rate",
        t2020."average_amount_sold" * (1 + ((t2020."average_amount_sold" - t2019."average_amount_sold") / t2019."average_amount_sold")) * c."to_us" AS "projected_amount_usd"
    FROM
        (
            SELECT
                t."calendar_month_number",
                AVG(s."amount_sold") AS "average_amount_sold"
            FROM
                "sales" s
            JOIN
                "customers" cu ON s."cust_id" = cu."cust_id"
            JOIN
                "countries" co ON cu."country_id" = co."country_id"
            JOIN
                "promotions" p ON s."promo_id" = p."promo_id"
            JOIN
                "channels" ch ON s."channel_id" = ch."channel_id"
            JOIN
                "times" t ON s."time_id" = t."time_id"
            WHERE
                co."country_name" = 'France'
                AND p."promo_total_id" = 1
                AND ch."channel_total_id" = 1
                AND t."calendar_year" = 2020
            GROUP BY
                t."calendar_month_number"
        ) t2020
    JOIN
        (
            SELECT
                t."calendar_month_number",
                AVG(s."amount_sold") AS "average_amount_sold"
            FROM
                "sales" s
            JOIN
                "customers" cu ON s."cust_id" = cu."cust_id"
            JOIN
                "countries" co ON cu."country_id" = co."country_id"
            JOIN
                "promotions" p ON s."promo_id" = p."promo_id"
            JOIN
                "channels" ch ON s."channel_id" = ch."channel_id"
            JOIN
                "times" t ON s."time_id" = t."time_id"
            WHERE
                co."country_name" = 'France'
                AND p."promo_total_id" = 1
                AND ch."channel_total_id" = 1
                AND t."calendar_year" = 2019
            GROUP BY
                t."calendar_month_number"
        ) t2019 ON t2020."calendar_month_number" = t2019."calendar_month_number"
    JOIN
        "currency" c ON c."country" = 'France' AND c."year" = 2021 AND c."month" = t2020."calendar_month_number"
)
, ranked_sales AS
(
    SELECT
        "projected_amount_usd" AS "projected_amount",
        ROW_NUMBER() OVER (ORDER BY "projected_amount_usd") AS "rn",
        COUNT(*) OVER () AS "cnt"
    FROM
        projected_sales
)
SELECT
    ROUND(AVG("projected_amount"), 4) AS "Median_Average_Monthly_Projected_Sales_USD"
FROM
    ranked_sales
WHERE
    (
        ("cnt" % 2 = 1 AND "rn" = ("cnt" + 1) / 2)
        OR
        ("cnt" % 2 = 0 AND "rn" IN ("cnt" / 2, "cnt" / 2 + 1))
    );