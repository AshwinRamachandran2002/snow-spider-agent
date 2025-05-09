/* 2–hop paths on Zilliqa from
   zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz  ➜  zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e     */
WITH edges AS (      -- confirmed transfers: regular txs + contract transitions
    SELECT
        "sender"                AS from_addr,
        "to_addr"               AS to_addr,
        "block_timestamp"       AS ts,
        "id"                    AS txid
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE "success" = TRUE
      AND "to_addr" IS NOT NULL
    
    UNION ALL
    
    SELECT
        "addr"                  AS from_addr,
        "recipient"             AS to_addr,
        "block_timestamp"       AS ts,
        "transaction_id"        AS txid
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSITIONS
    WHERE "recipient" IS NOT NULL
),

-- outgoing‑tx count for every address (used to filter intermediates)
out_deg AS (
    SELECT
        from_addr,
        COUNT(*) AS out_cnt
    FROM edges
    GROUP BY from_addr
),

-- first hop :  source ➜ X
first_hop AS (
    SELECT *
    FROM edges
    WHERE from_addr = 'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz'
),

-- second hop :  X ➜ destination
second_hop AS (
    SELECT *
    FROM edges
    WHERE to_addr = 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
),

-- stitch hops, keep chronological order and require intermediate to have ≤50 outgoing txs
paths AS (
    SELECT
        f.from_addr                       AS source,
        f.to_addr                         AS intermediate,
        s.to_addr                         AS destination,
        f.txid                            AS tx1,
        s.txid                            AS tx2,
        f.ts                              AS ts1,
        s.ts                              AS ts2
    FROM first_hop f
    JOIN second_hop s
          ON f.to_addr = s.from_addr
         AND s.ts >= f.ts                        -- chronological
    JOIN out_deg d                              -- filter intermediates
          ON d.from_addr = f.to_addr
         AND d.out_cnt <= 50                    -- ≤50 outgoing txs
)

SELECT
    CONCAT(
        source,
        ' --(tx ', SUBSTR(tx1,1,5), '..)--> ',
        intermediate,
        ' --(tx ', SUBSTR(tx2,1,5), '..)--> ',
        destination
    ) AS "path"
FROM paths
ORDER BY ts1 ASC, ts2 ASC;