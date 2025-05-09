WITH
/*-------------------------------------------------
1)  Unified outgoing “edges”
--------------------------------------------------*/
reg_tx AS (
    SELECT
        "sender"          AS sender ,
        "to_addr"         AS receiver ,
        "id"              AS tx_id ,
        "block_timestamp" AS ts
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE "success" = TRUE
),
ctr_tx AS (
    SELECT
        "addr"            AS sender ,
        "recipient"       AS receiver ,
        "transaction_id"  AS tx_id ,
        "block_timestamp" AS ts
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSITIONS
),
edges AS (
    SELECT * FROM reg_tx
    UNION ALL
    SELECT * FROM ctr_tx
),

/*-------------------------------------------------
2)  Low-activity addresses (≤ 50 outgoing txs)
--------------------------------------------------*/
low_activity AS (
    SELECT sender AS addr
    FROM edges
    GROUP BY sender
    HAVING COUNT(*) <= 50
),

/*-------------------------------------------------
3)  First and second hop candidates
--------------------------------------------------*/
leg1 AS (   -- source → intermediate
    SELECT
        receiver      AS interm ,
        tx_id         AS tx1 ,
        ts            AS ts1
    FROM edges
    WHERE sender = 'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz'
),
leg2 AS (   -- intermediate → destination
    SELECT
        sender        AS interm ,
        tx_id         AS tx2 ,
        ts            AS ts2
    FROM edges
    WHERE receiver = 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
),

/*-------------------------------------------------
4)  Exact 2-hop paths (chronological)
--------------------------------------------------*/
paths_raw AS (
    SELECT DISTINCT
        CONCAT(
            'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz',
            ' --(tx ', LEFT(l1.tx1,5), '..)--> ',
            l1.interm,
            ' --(tx ', LEFT(l2.tx2,5), '..)--> ',
            'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
        )     AS path,
        l1.ts1            AS ts1
    FROM      leg1 l1
    JOIN      leg2 l2  ON l1.interm = l2.interm
                      AND l2.ts2  > l1.ts1          -- chronological order
    JOIN      low_activity la ON la.addr = l1.interm
)

/*-------------------------------------------------
5)  Final output ordered chronologically
--------------------------------------------------*/
SELECT path
FROM paths_raw
ORDER BY ts1;