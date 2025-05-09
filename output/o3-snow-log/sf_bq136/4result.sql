WITH edges AS (  -- all confirmed value-moving edges
    /* regular ZIL transfers */
    SELECT
        "sender"          AS "from_addr",
        "to_addr"         AS "to_addr",
        "id"              AS "txid",
        "block_timestamp" AS "ts"
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE "success" = TRUE
      AND "sender" IS NOT NULL
      AND "to_addr" IS NOT NULL

    UNION ALL

    /* contract-driven transfers (TRANSITIONS) */
    SELECT
        "addr"            AS "from_addr",
        "recipient"       AS "to_addr",
        "transaction_id"  AS "txid",
        "block_timestamp" AS "ts"
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSITIONS
    WHERE "addr"      IS NOT NULL
      AND "recipient" IS NOT NULL
      AND ( "amount" IS NULL OR "amount" > 0 )      -- keep value or unknown
),
/* how many outgoing tx every address has */
outgoing_cnt AS (
    SELECT "from_addr", COUNT(*) AS cnt
    FROM edges
    GROUP BY "from_addr"
),
/* first hop: source ➜ any intermediate */
first_hop AS (
    SELECT e.*
    FROM edges e
    WHERE e."from_addr" = 'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz'
),
/* second hop: intermediate ➜ destination,   intermediate must be “small degree” (≤50) */
second_hop AS (
    SELECT
        fh."txid"  AS tx1,
        fh."ts"    AS ts1,
        fh."to_addr" AS inter_addr,
        e2."txid"  AS tx2,
        e2."ts"    AS ts2
    FROM first_hop      fh
    JOIN edges          e2  ON e2."from_addr" = fh."to_addr"
                           AND e2."to_addr"   = 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
                           AND e2."ts"        > fh."ts"          -- chronological
    JOIN outgoing_cnt   oc  ON oc."from_addr" = fh."to_addr"
                           AND oc.cnt <= 50                      -- exclude “busy” wallets
)
SELECT DISTINCT
       'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz'
       || ' --(tx ' || SUBSTR(tx1,1,5) || ')--> '
       || inter_addr
       || ' --(tx ' || SUBSTR(tx2,1,5) || ')--> '
       || 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'   AS "path"
FROM second_hop
ORDER BY "path";