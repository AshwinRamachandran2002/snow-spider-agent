WITH
edges AS (
    /* regular on-chain transfers              */
    SELECT
        LOWER("sender")        AS from_addr,
        LOWER("to_addr")       AS to_addr,
        "id"                   AS txid,
        "block_timestamp"      AS ts
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE "success" = TRUE
      AND "sender" IS NOT NULL
      AND "to_addr" IS NOT NULL

    UNION ALL

    /* contract transitions that move value    */
    SELECT
        LOWER("addr")          AS from_addr,
        LOWER("recipient")     AS to_addr,
        "transaction_id"       AS txid,
        "block_timestamp"      AS ts
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSITIONS
    WHERE "addr" IS NOT NULL
      AND "recipient" IS NOT NULL
),
/* how busy is every potential intermediate ? */
outgoing_cnt AS (
    SELECT from_addr, COUNT(*) AS tx_out
    FROM edges
    GROUP BY from_addr
),
/* permitted intermediates (≤ 50 out-tx)      */
good_inter AS (
    SELECT from_addr
    FROM outgoing_cnt
    WHERE tx_out <= 50
),
/* first hop: from the given source address   */
h1 AS (
    SELECT *
    FROM edges
    WHERE from_addr = 'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz'
),
/* second hop: into the given destination     */
h2 AS (
    SELECT *
    FROM edges
    WHERE to_addr = 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
)

SELECT
    CONCAT(
        h1.from_addr,
        ' --(tx ', SUBSTR(h1.txid,1,5), ')--> ',
        h1.to_addr,
        ' --(tx ', SUBSTR(h2.txid,1,5), ')--> ',
        h2.to_addr
    )                                                            AS path
FROM h1
JOIN h2
      ON  h1.to_addr      = h2.from_addr            /* same intermediate */
      AND h1.ts           < h2.ts                   /* chronological     */
JOIN good_inter gi
      ON  gi.from_addr    = h1.to_addr              /* intermediate OK   */
WHERE h1.to_addr NOT IN (
          'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz',
          'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
      )                                             /* avoid trivial I   */
ORDER BY h1.ts NULLS LAST;