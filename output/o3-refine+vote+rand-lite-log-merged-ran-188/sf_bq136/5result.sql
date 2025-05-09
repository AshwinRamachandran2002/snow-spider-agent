WITH
-- every outgoing tx / transition from the given *source*
first_leg AS (
    /* regular transactions ------------------------------------------------- */
    SELECT
        "to_addr"                       AS intermediate,
        "id"                            AS tx_id,
        "block_timestamp"               AS ts
    FROM   CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE  "sender"  = 'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz'
      AND  "success" = TRUE

    UNION ALL
    /* contract-call transitions ------------------------------------------- */
    SELECT
        "recipient"                     AS intermediate,
        "transaction_id"                AS tx_id,
        "block_timestamp"               AS ts
    FROM   CRYPTO.CRYPTO_ZILLIQA.TRANSITIONS
    WHERE  "addr" = 'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz'
),

-- every outgoing tx / transition that finally reaches the *destination*
second_leg AS (
    /* regular transactions ------------------------------------------------- */
    SELECT
        "sender"                        AS intermediate,
        "id"                            AS tx_id,
        "block_timestamp"               AS ts
    FROM   CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE  "to_addr"  = 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
      AND  "success" = TRUE

    UNION ALL
    /* contract-call transitions ------------------------------------------- */
    SELECT
        "addr"                          AS intermediate,
        "transaction_id"                AS tx_id,
        "block_timestamp"               AS ts
    FROM   CRYPTO.CRYPTO_ZILLIQA.TRANSITIONS
    WHERE  "recipient" = 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
),

-- compute how “busy” every address is (tx-count across BOTH tables)
outgoing_counts AS (
    SELECT   address,
             COUNT(*) AS cnt
    FROM   (
              SELECT "sender" AS address FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
              UNION ALL
              SELECT "addr"   AS address FROM CRYPTO.CRYPTO_ZILLIQA.TRANSITIONS
           )
    GROUP BY address
),

-- keep only low-activity addresses (≤ 50 outgoing txs)
low_activity AS (
    SELECT address
    FROM   outgoing_counts
    WHERE  cnt <= 50
),

-- stitch the two hops together in chronological order
two_hop_paths AS (
    SELECT
        fl.intermediate,
        fl.tx_id  AS tx1_id,
        sl.tx_id  AS tx2_id,
        fl.ts     AS ts1,
        sl.ts     AS ts2
    FROM   first_leg  fl
    JOIN   second_leg sl
           ON  fl.intermediate = sl.intermediate
           AND sl.ts > fl.ts                          -- chronological order
    JOIN   low_activity la
           ON  fl.intermediate = la.address           -- filter busy wallets
)

SELECT
    CONCAT(
        'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz',
        ' --(tx ', LEFT(tx1_id,5), ')--> ',
        intermediate,
        ' --(tx ', LEFT(tx2_id,5), ')--> ',
        'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
    ) AS path
FROM   two_hop_paths
ORDER BY ts1 NULLS FIRST;