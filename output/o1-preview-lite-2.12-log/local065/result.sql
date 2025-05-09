SELECT ROUND(
    SUM(
        CASE
            WHEN pn."pizza_name" = 'Meatlovers' THEN 12
            WHEN pn."pizza_name" = 'Vegetarian' THEN 10
            ELSE 0
        END
        +
        CASE
            WHEN pc."extras" IS NOT NULL AND TRIM(pc."extras") != '' THEN
                LENGTH(pc."extras") - LENGTH(REPLACE(pc."extras", ',', '')) + 1
            ELSE 0
        END
    ), 4
) AS Total_Earnings
FROM
    "pizza_clean_customer_orders" pc
    JOIN "pizza_names" pn ON pc."pizza_id" = pn."pizza_id"
    LEFT JOIN "pizza_clean_runner_orders" pr ON pc."order_id" = pr."order_id"
WHERE
    pn."pizza_name" IN ('Meatlovers', 'Vegetarian')
    AND (pr."cancellation" IS NULL OR pr."cancellation" = '');