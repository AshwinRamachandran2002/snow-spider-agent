-- Task: Calculate the total income from all completed pizza orders. Meat Lovers pizzas are priced at $12, Vegetarian pizzas at $10, and any other pizzas at $0. Include $1 for each extra topping per order, determined by counting items in the 'extras' column where toppings are listed as comma-separated values. Ensure that canceled orders are filtered out by selecting orders where the 'cancellation' field is NULL or empty. How much money has Pizza Runner earned in total?

WITH completed_orders AS (
    SELECT co."order_id", co."pizza_id", co."extras"
    FROM MODERN_DATA.MODERN_DATA.PIZZA_CUSTOMER_ORDERS co
    JOIN MODERN_DATA.MODERN_DATA.PIZZA_RUNNER_ORDERS ro
      ON co."order_id" = ro."order_id"
    WHERE ro."cancellation" IS NULL OR ro."cancellation" = ''
),
price_per_pizza AS (
    SELECT pn."pizza_id",
        CASE
            WHEN pn."pizza_name" = 'Meatlovers' THEN 12
            WHEN pn."pizza_name" = 'Vegetarian' THEN 10
            ELSE 0
        END AS base_price
    FROM MODERN_DATA.MODERN_DATA.PIZZA_NAMES pn
)
SELECT SUM(p.base_price + 
    CASE 
        WHEN c."extras" IS NULL OR c."extras" = '' THEN 0
        ELSE (LENGTH(c."extras") - LENGTH(REPLACE(c."extras", ',', ''))) + 1
    END
    ) AS total_income
FROM completed_orders c
JOIN price_per_pizza p
  ON c."pizza_id" = p."pizza_id";