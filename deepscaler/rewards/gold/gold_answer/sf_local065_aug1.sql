-- Task: List the pizza IDs and their base prices for Meat Lovers and Vegetarian pizzas.
SELECT pn."pizza_id",
    CASE
        WHEN pn."pizza_name" = 'Meatlovers' THEN 12
        WHEN pn."pizza_name" = 'Vegetarian' THEN 10
        ELSE 0
    END AS base_price
FROM MODERN_DATA.MODERN_DATA.PIZZA_NAMES pn;