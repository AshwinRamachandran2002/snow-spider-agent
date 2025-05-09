/*  ---------------------------------------------------------------
    2‑hop routes on Zilliqa
    source      : zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz
    destination : zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e
    rule        : intermediate address must have ≤ 50 outgoing tx
----------------------------------------------------------------- */
WITH
/* ---------- 1. confirmed on‑chain records --------------------------- */
regular AS (
    SELECT
        "id"              AS "tx_id",
        "sender"          AS "from_addr",
        "to_addr"         AS "to_addr",
        "block_timestamp" AS "ts"
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE "to_addr" IS NOT NULL
),
transition AS (
    SELECT
        "transaction_id"  AS "tx_id",
        "addr"            AS "from_addr",
        "recipient"       AS "to_addr",
        "block_timestamp" AS "ts"
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSITIONS
    WHERE "recipient" IS NOT NULL
),

/* ---------- 2. addresses with ≤ 50 outgoing tx ---------------------- */
all_outgoing AS (
    SELECT "from_addr" AS "address" FROM regular
    UNION ALL
    SELECT "from_addr" FROM transition
),
out_cnt AS (
    SELECT "address"
    FROM all_outgoing
    WHERE "address" IS NOT NULL
    GROUP BY "address"
    HAVING COUNT(*) <= 50
),

/* ---------- 3. construct four 2‑hop patterns ----------------------- */
paths_tx_tx AS (
    SELECT
        CONCAT(
            'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz',
            ' --(tx ', LEFT(t1."tx_id", 5), ')--> ',
            t1."to_addr",
            ' --(tx ', LEFT(t2."tx_id", 5), ')--> ',
            'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
        ) AS "transaction_path"
    FROM regular t1
    JOIN regular t2          ON t1."to_addr" = t2."from_addr"
    JOIN out_cnt oc          ON oc."address" = t1."to_addr"
    WHERE t1."from_addr" = 'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz'
      AND t2."to_addr"   = 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
      AND t2."ts"        > t1."ts"
),
paths_tx_tr AS (
    SELECT
        CONCAT(
            'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz',
            ' --(tx ', LEFT(t1."tx_id", 5), ')--> ',
            t1."to_addr",
            ' --(tx ', LEFT(t2."tx_id", 5), ')--> ',
            'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
        ) AS "transaction_path"
    FROM regular t1
    JOIN transition t2       ON t1."to_addr" = t2."from_addr"
    JOIN out_cnt oc          ON oc."address" = t1."to_addr"
    WHERE t1."from_addr" = 'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz'
      AND t2."to_addr"   = 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
      AND t2."ts"        > t1."ts"
),
paths_tr_tx AS (
    SELECT
        CONCAT(
            'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz',
            ' --(tx ', LEFT(t1."tx_id", 5), ')--> ',
            t1."to_addr",
            ' --(tx ', LEFT(t2."tx_id", 5), ')--> ',
            'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
        ) AS "transaction_path"
    FROM transition t1
    JOIN regular t2          ON t1."to_addr" = t2."from_addr"
    JOIN out_cnt oc          ON oc."address" = t1."to_addr"
    WHERE t1."from_addr" = 'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz'
      AND t2."to_addr"   = 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
      AND t2."ts"        > t1."ts"
),
paths_tr_tr AS (
    SELECT
        CONCAT(
            'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz',
            ' --(tx ', LEFT(t1."tx_id", 5), ')--> ',
            t1."to_addr",
            ' --(tx ', LEFT(t2."tx_id", 5), ')--> ',
            'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
        ) AS "transaction_path"
    FROM transition t1
    JOIN transition t2       ON t1."to_addr" = t2."from_addr"
    JOIN out_cnt oc          ON oc."address" = t1."to_addr"
    WHERE t1."from_addr" = 'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz'
      AND t2."to_addr"   = 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
      AND t2."ts"        > t1."ts"
)

/* ---------- 4. unify & return --------------------------------------- */
SELECT DISTINCT "transaction_path"
FROM (
    SELECT * FROM paths_tx_tx
    UNION ALL
    SELECT * FROM paths_tx_tr
    UNION ALL
    SELECT * FROM paths_tr_tx
    UNION ALL
    SELECT * FROM paths_tr_tr
)
ORDER BY "transaction_path";