WITH
edges AS (          -- confirmed value-transfers (regular txs + contract transitions)
    ---------------------------------------------------------------- regular txs
    SELECT  "id"              AS tx_id,
            "sender"          AS from_addr,
            "to_addr"         AS to_addr,
            "block_timestamp" AS ts
    FROM    CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE   "success" = TRUE
      AND   "sender" IS NOT NULL
      AND   "to_addr" IS NOT NULL

    UNION ALL
    ---------------------------------------------------------------- contract transitions
    SELECT  "transaction_id"  AS tx_id,
            "addr"            AS from_addr,
            "recipient"       AS to_addr,
            "block_timestamp" AS ts
    FROM    CRYPTO.CRYPTO_ZILLIQA.TRANSITIONS
    WHERE   "addr" IS NOT NULL
      AND   "recipient" IS NOT NULL
),
------------------------------------------------------------------- count outgoing per address
outgoing_cnt AS (
    SELECT  from_addr,
            COUNT(*) AS cnt_out
    FROM    edges
    GROUP BY from_addr
),
------------------------------------------------------------------- first hop (source -> X)
first_hop AS (
    SELECT  e.tx_id           AS tx1,
            e.to_addr         AS intermediate_addr,
            e.ts              AS ts1
    FROM    edges e
    JOIN    outgoing_cnt c
           ON e.to_addr = c.from_addr
    WHERE   e.from_addr = 'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz'
      AND   c.cnt_out  <= 50                       -- keep low-activity intermediates
),
------------------------------------------------------------------- second hop (X -> destination)
second_hop AS (
    SELECT  e.tx_id           AS tx2,
            e.from_addr       AS intermediate_addr,
            e.ts              AS ts2
    FROM    edges e
    JOIN    outgoing_cnt c
           ON e.from_addr = c.from_addr
    WHERE   e.to_addr = 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
      AND   c.cnt_out <= 50
),
------------------------------------------------------------------- build chronological 2-hop paths
paths AS (
    SELECT  f.tx1,
            f.intermediate_addr,
            s.tx2
    FROM    first_hop  f
    JOIN    second_hop s
           ON  f.intermediate_addr = s.intermediate_addr
          AND f.ts1 < s.ts2                          -- chronological order
)
------------------------------------------------------------------- final presentation
SELECT DISTINCT
       'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz'
       || ' --(tx ' || SUBSTR(tx1,1,5) || ')--> '
       || intermediate_addr
       || ' --(tx ' || SUBSTR(tx2,1,5) || ')--> '
       || 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'        AS "2_HOP_PATH"
FROM   paths
ORDER BY "2_HOP_PATH";