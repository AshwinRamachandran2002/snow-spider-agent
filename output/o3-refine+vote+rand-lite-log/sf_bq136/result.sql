/* 2‑hop paths on Zilliqa from
      zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz   (SRC)
   to  zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e (DST)
   – regular txs + contract transitions
   – intermediate address ≤ 50 outgoing txs
   – chronological order                           */
WITH "EDGES" AS (      /* confirmed outward edges                     */
    SELECT
        "sender"          AS "FROM_ADDR",
        "to_addr"         AS "TO_ADDR",
        "id"              AS "TX_ID",
        "block_timestamp" AS "TS"
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE "success" = TRUE
      AND "to_addr" IS NOT NULL

    UNION ALL

    SELECT
        "addr"            AS "FROM_ADDR",
        "recipient"       AS "TO_ADDR",
        "transaction_id"  AS "TX_ID",
        "block_timestamp" AS "TS"
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSITIONS
    WHERE "recipient" IS NOT NULL
),
/* outgoing‑count per address */
"OUT_CNT" AS (
    SELECT "FROM_ADDR", COUNT(*) AS "OUT_TXS"
    FROM "EDGES"
    GROUP BY "FROM_ADDR"
),
/* build all possible 2‑hop chains SRC → X → DST */
"FIRST_HOP" AS (
    SELECT *
    FROM "EDGES"
    WHERE "FROM_ADDR" = 'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz'
),
"SECOND_HOP" AS (
    SELECT *
    FROM "EDGES"
    WHERE "TO_ADDR" = 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
),
"RAW_PATHS" AS (
    SELECT
        fh."TO_ADDR"          AS "MID_ADDR",
        fh."TX_ID"            AS "TX1",
        fh."TS"               AS "TS1",
        sh."TX_ID"            AS "TX2",
        sh."TS"               AS "TS2"
    FROM "FIRST_HOP" fh
    JOIN "SECOND_HOP" sh
      ON fh."TO_ADDR" = sh."FROM_ADDR"
     AND fh."TS"      < sh."TS"        -- chronological
),
/* apply activity filter to intermediate address */
"FILTERED" AS (
    SELECT  r.*
    FROM    "RAW_PATHS" r
    JOIN    "OUT_CNT"  c
      ON    r."MID_ADDR" = c."FROM_ADDR"
    WHERE   c."OUT_TXS" <= 50
      AND   r."MID_ADDR" NOT IN (
              'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz',
              'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
            )
)
SELECT DISTINCT
       CONCAT(
           'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz',
           ' --(tx ', SUBSTR("TX1",1,5),'..)--> ',
           "MID_ADDR",
           ' --(tx ', SUBSTR("TX2",1,5),'..)--> ',
           'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
       ) AS "PATH"
FROM "FILTERED"
ORDER BY "PATH";