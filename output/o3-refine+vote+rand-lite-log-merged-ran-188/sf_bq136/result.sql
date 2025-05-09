WITH
/* -------- first hop : SOURCE  -->  INTERMEDIATE ------------------------------------ */
src_regular AS (   -- regular payments
    SELECT 
        "id"                 AS "tx_id",
        "to_addr"            AS "intermediate",
        "block_timestamp"    AS "ts"
    FROM   CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE  "sender"  = 'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz'
      AND  "success" = TRUE                             -- confirmed txs
),
src_contract AS (  -- contract transitions
    SELECT
        "transaction_id"     AS "tx_id",
        "recipient"          AS "intermediate",
        "block_timestamp"    AS "ts"
    FROM   CRYPTO.CRYPTO_ZILLIQA.TRANSITIONS
    WHERE  "addr" = 'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz'
),
first_leg AS (
    SELECT * FROM src_regular
    UNION ALL
    SELECT * FROM src_contract
),

/* -------- second hop : same INTERMEDIATE  -->  DESTINATION ------------------------- */
dst_regular AS (   -- regular payments
    SELECT
        "id"                 AS "tx_id",
        "sender"             AS "intermediate",
        "block_timestamp"    AS "ts"
    FROM   CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE  "to_addr"  = 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
      AND  "success"  = TRUE
),
dst_contract AS (  -- contract transitions
    SELECT
        "transaction_id"     AS "tx_id",
        "addr"               AS "intermediate",
        "block_timestamp"    AS "ts"
    FROM   CRYPTO.CRYPTO_ZILLIQA.TRANSITIONS
    WHERE  "recipient" = 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
),
second_leg AS (
    SELECT * FROM dst_regular
    UNION ALL
    SELECT * FROM dst_contract
),

/* -------- low–activity filter : ≤ 50 outgoing txs / transitions -------------------- */
out_cnt AS (
    SELECT "sender" AS "address", COUNT(*) AS cnt
    FROM   CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    GROUP  BY "sender"
    UNION ALL
    SELECT "addr"   AS "address", COUNT(*) AS cnt
    FROM   CRYPTO.CRYPTO_ZILLIQA.TRANSITIONS
    GROUP  BY "addr"
),
low_activity AS (
    SELECT "address"
    FROM   out_cnt
    GROUP  BY "address"
    HAVING SUM(cnt) <= 50
)

/* -------- assemble 2-hop paths ----------------------------------------------------- */
SELECT DISTINCT
       'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz'
       || ' --(tx ' || SUBSTR(f."tx_id",1,5) || ')--> '
       || f."intermediate"
       || ' --(tx ' || SUBSTR(s."tx_id",1,5) || ')--> '
       || 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'          AS "2hop_path"
FROM   first_leg  f
JOIN   second_leg s
          ON  f."intermediate" = s."intermediate"
         AND  f."ts" < s."ts"                    -- chronological order
JOIN   low_activity la
          ON  f."intermediate" = la."address"
;