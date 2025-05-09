SELECT s."month" AS "Month_num", t."calendar_month_name" AS "Month", ROUND(AVG(s."projected_amount_usd"), 4) AS "Average_Projected_Sales_USD"
FROM
(
    SELECT s2020."prod_id", s2020."month",
           (s2020."amount_2020" * (1 + COALESCE(g."growth_rate", 0))) * c."to_us" AS "projected_amount_usd"
    FROM
    (
        -- Get 2020 monthly sales per product
        SELECT s."prod_id", t."calendar_month_number" AS "month", SUM(s."amount_sold") AS "amount_2020"
        FROM "sales" s
        JOIN "customers" cu ON s."cust_id" = cu."cust_id"
        JOIN "countries" co ON cu."country_id" = co."country_id"
        JOIN "promotions" p ON s."promo_id" = p."promo_id"
        JOIN "channels" ch ON s."channel_id" = ch."channel_id"
        JOIN "times" t ON s."time_id" = t."time_id"
        WHERE co."country_name" = 'France'
          AND p."promo_total_id" = 1
          AND ch."channel_total_id" = 1
          AND t."calendar_year" = 2020
        GROUP BY s."prod_id", t."calendar_month_number"
    ) s2020
    LEFT JOIN
    (
        -- Calculate growth rate from 2019 to 2020
        SELECT s2019."prod_id", s2019."month",
               (s2020."amount_2020" - s2019."amount_2019") / NULLIF(s2019."amount_2019", 0) AS "growth_rate"
        FROM
        (
            -- Get 2019 monthly sales per product
            SELECT s."prod_id", t."calendar_month_number" AS "month", SUM(s."amount_sold") AS "amount_2019"
            FROM "sales" s
            JOIN "customers" cu ON s."cust_id" = cu."cust_id"
            JOIN "countries" co ON cu."country_id" = co."country_id"
            JOIN "promotions" p ON s."promo_id" = p."promo_id"
            JOIN "channels" ch ON s."channel_id" = ch."channel_id"
            JOIN "times" t ON s."time_id" = t."time_id"
            WHERE co."country_name" = 'France'
              AND p."promo_total_id" = 1
              AND ch."channel_total_id" = 1
              AND t."calendar_year" = 2019
            GROUP BY s."prod_id", t."calendar_month_number"
        ) s2019
        JOIN
        (
            -- Use the same 2020 sales data
            SELECT s."prod_id", t."calendar_month_number" AS "month", SUM(s."amount_sold") AS "amount_2020"
            FROM "sales" s
            JOIN "customers" cu ON s."cust_id" = cu."cust_id"
            JOIN "countries" co ON cu."country_id" = co."country_id"
            JOIN "promotions" p ON s."promo_id" = p."promo_id"
            JOIN "channels" ch ON s."channel_id" = ch."channel_id"
            JOIN "times" t ON s."time_id" = t."time_id"
            WHERE co."country_name" = 'France'
              AND p."promo_total_id" = 1
              AND ch."channel_total_id" = 1
              AND t."calendar_year" = 2020
            GROUP BY s."prod_id", t."calendar_month_number"
        ) s2020 ON s2019."prod_id" = s2020."prod_id" AND s2019."month" = s2020."month"
    ) g ON s2020."prod_id" = g."prod_id" AND s2020."month" = g."month"
    JOIN "currency" c ON c."country" = 'France' AND c."year" = 2021 AND c."month" = s2020."month"
) s
JOIN
(
    -- Get distinct month names
    SELECT DISTINCT "calendar_month_number" AS "month", "calendar_month_name"
    FROM "times"
) t ON s."month" = t."month"
GROUP BY s."month", t."calendar_month_name"
ORDER BY s."month";