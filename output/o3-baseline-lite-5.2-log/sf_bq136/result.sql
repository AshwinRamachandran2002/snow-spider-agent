WITH
-- 1.  All confirmed outward “edges” (regular txs + contract transitions)
"EDGES" AS (
    /* regular user ↦ address transfers */
    SELECT
        "sender"      AS "FROM_ADDR",
        "to_addr"     AS "TO_ADDR",
        "block_timestamp"  AS "TS",
        "id"          AS "TX_ID"
    FROM  CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE "success" = TRUE                      -- confirmed on–chain
      AND "to_addr" IS NOT NULL

    UNION ALL

    /* contract‐transition transfers (contract ↦ recipient) */
    SELECT
        "addr"        AS "FROM_ADDR",
        "recipient"   AS "TO_ADDR",
        "block_timestamp"  AS "TS",
        "transaction_id"   AS "TX_ID"
    FROM  CRYPTO.CRYPTO_ZILLIQA.TRANSITIONS
    WHERE "recipient" IS NOT NULL
),

-- 2.  Out‑degree (number of outgoing txs) for every address
"OUT_DEGREE" AS (
    SELECT
        "FROM_ADDR",
        COUNT(*) AS "OUT_CNT"
    FROM "EDGES"
    GROUP BY "FROM_ADDR"
),

-- 3.  First hop :  source ➜ intermediate
"FIRST_HOP" AS (
    SELECT
        e1."TO_ADDR"          AS "INTERMEDIATE",
        e1."TX_ID"            AS "TX1_ID",
        e1."TS"               AS "TS1"
    FROM  "EDGES" e1
    WHERE e1."FROM_ADDR" = 'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz'
),

-- 4.  Second hop : intermediate ➜ destination
"SECOND_HOP" AS (
    SELECT
        e2."FROM_ADDR"        AS "INTERMEDIATE",
        e2."TX_ID"            AS "TX2_ID",
        e2."TS"               AS "TS2"
    FROM  "EDGES" e2
    WHERE e2."TO_ADDR" = 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
)

-- 5.  Assemble 2‑hop paths, apply time order & activity filter
SELECT
    CONCAT(
        'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz',
        ' --(tx ', SUBSTR(f."TX1_ID",1,5), ')--> ',
        f."INTERMEDIATE",
        ' --(tx ', SUBSTR(s."TX2_ID",1,5), ')--> ',
        'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
    ) AS "PATH"
FROM      "FIRST_HOP"  f
JOIN      "SECOND_HOP" s  ON s."INTERMEDIATE" = f."INTERMEDIATE"
JOIN      "OUT_DEGREE" d  ON d."FROM_ADDR"   = f."INTERMEDIATE"
WHERE     d."OUT_CNT" <= 50           -- exclude high‑activity wallets
  AND     f."TS1" < s."TS2"           -- chronological order
ORDER BY  f."TS1" ASC, s."TS2" ASC;