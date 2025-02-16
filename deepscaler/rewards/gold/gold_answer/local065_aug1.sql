-- Task: Calculate the total revenue from Meat Lovers pizzas priced at $12 and Vegetarian pizzas at $10, excluding canceled orders. Do not include extra toppings.
SELECT
    SUM(
        CASE
            WHEN t1.pizza_id = 1 THEN 12
            WHEN t1.pizza_id = 2 THEN 10
        END
    ) AS total_revenue
FROM
    "pizza_clean_customer_orders" AS t1
JOIN
    "pizza_clean_runner_orders" AS t2
ON
    t2.order_id = t1.order_id
WHERE
    t2.cancellation IS NULL;