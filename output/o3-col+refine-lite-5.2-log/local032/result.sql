/* Top sellers in four different “best‑of” categories (delivered orders only) */
SELECT *
FROM (
        /* 1) Most distinct customer unique IDs served */
        SELECT
            'most_distinct_customers'      AS achievement,
            t.seller_id                    AS seller_id,
            t.distinct_customers           AS value
        FROM (
                SELECT   oi.seller_id,
                         COUNT(DISTINCT c.customer_unique_id) AS distinct_customers
                FROM     olist_order_items  AS oi
                JOIN     olist_orders       AS o  ON o.order_id = oi.order_id
                                                 AND o.order_status = 'delivered'
                JOIN     olist_customers    AS c  ON c.customer_id = o.customer_id
                GROUP BY oi.seller_id
                ORDER BY distinct_customers DESC, oi.seller_id
                LIMIT 1
        ) t

        UNION ALL

        /* 2) Highest total profit (price – freight_value) */
        SELECT
            'highest_profit'               AS achievement,
            t.seller_id                    AS seller_id,
            t.total_profit                 AS value
        FROM (
                SELECT   oi.seller_id,
                         SUM(oi.price - oi.freight_value) AS total_profit
                FROM     olist_order_items AS oi
                JOIN     olist_orders      AS o  ON o.order_id = oi.order_id
                                                AND o.order_status = 'delivered'
                GROUP BY oi.seller_id
                ORDER BY total_profit DESC, oi.seller_id
                LIMIT 1
        ) t

        UNION ALL

        /* 3) Most distinct delivered orders handled */
        SELECT
            'most_distinct_orders'         AS achievement,
            t.seller_id                    AS seller_id,
            t.distinct_orders              AS value
        FROM (
                SELECT   oi.seller_id,
                         COUNT(DISTINCT oi.order_id) AS distinct_orders
                FROM     olist_order_items AS oi
                JOIN     olist_orders      AS o  ON o.order_id = oi.order_id
                                                AND o.order_status = 'delivered'
                GROUP BY oi.seller_id
                ORDER BY distinct_orders DESC, oi.seller_id
                LIMIT 1
        ) t

        UNION ALL

        /* 4) Most 5‑star reviews received */
        SELECT
            'most_5_star_reviews'          AS achievement,
            t.seller_id                    AS seller_id,
            t.five_star_reviews            AS value
        FROM (
                SELECT   oi.seller_id,
                         COUNT(*) AS five_star_reviews
                FROM     olist_order_items   AS oi
                JOIN     olist_orders        AS o ON o.order_id = oi.order_id
                                                 AND o.order_status = 'delivered'
                JOIN     olist_order_reviews AS r ON r.order_id = oi.order_id
                                                 AND r.review_score = 5
                GROUP BY oi.seller_id
                ORDER BY five_star_reviews DESC, oi.seller_id
                LIMIT 1
        ) t
);