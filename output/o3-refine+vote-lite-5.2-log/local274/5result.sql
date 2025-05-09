WITH fifo_picks AS (
    /* 1.  All pick‑lines that belong to order 421.
           They are paired with the purchase that originally
           brought the goods into stock so the rows can be
           considered in FIFO (earliest purchase first).       */
    SELECT
        pl.product_id,
        pl.qty,
        pu.purchased      -- purchase date (earlier = first‑in)
    FROM   picking_line  AS pl
    JOIN   inventory     AS iv  ON iv.location_id = pl.location_id
                               AND iv.product_id  = pl.product_id
    JOIN   purchases     AS pu  ON pu.id = iv.purchase_id
    WHERE  pl.order_id = 421
),
/* 2.  Rank the pick rows inside each product by purchase date
       (earlier stock is consumed first: FIFO).                */
ranked AS (
    SELECT
        product_id,
        qty,
        ROW_NUMBER() OVER (
            PARTITION BY product_id
            ORDER BY     purchased          -- FIFO order
        ) AS fifo_rank
    FROM fifo_picks
)
/* 3.  Average the picked quantities per product.               */
SELECT
    product_id,
    AVG(qty) AS avg_units_picked
FROM   ranked
GROUP  BY product_id
ORDER  BY product_id;