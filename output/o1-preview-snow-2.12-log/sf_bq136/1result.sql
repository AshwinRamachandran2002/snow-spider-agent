WITH first_hop AS (
    SELECT
        t1."id" AS "tx1_id",
        t1."to_addr" AS "intermediary_address",
        t1."sender" AS "from_address"
    FROM
        "CRYPTO"."CRYPTO_ZILLIQA"."TRANSACTIONS" AS t1
    WHERE
        t1."sender" = 'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz'
),
filtered_intermediaries AS (
    SELECT
        fh."intermediary_address"
    FROM
        first_hop fh
    JOIN (
        SELECT
            "sender" AS "intermediary_address"
        FROM
            "CRYPTO"."CRYPTO_ZILLIQA"."TRANSACTIONS"
        GROUP BY
            "sender"
        HAVING
            COUNT(*) <= 50
    ) ioc ON fh."intermediary_address" = ioc."intermediary_address"
),
second_hop AS (
    SELECT
        t2."id" AS "tx2_id",
        t2."sender" AS "intermediary_address",
        t2."to_addr" AS "to_address"
    FROM
        "CRYPTO"."CRYPTO_ZILLIQA"."TRANSACTIONS" AS t2
    WHERE
        t2."to_addr" = 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
),
paths AS (
    SELECT DISTINCT
        fh."from_address",
        fh."tx1_id",
        fh."intermediary_address",
        sh."tx2_id",
        sh."to_address"
    FROM
        first_hop fh
    JOIN
        filtered_intermediaries fi ON fh."intermediary_address" = fi."intermediary_address"
    JOIN
        second_hop sh ON fi."intermediary_address" = sh."intermediary_address"
)
SELECT
    p."from_address",
    CONCAT(
        p."from_address",
        ' --(tx ',
        LEFT(p."tx1_id", 5),
        '..)--> ',
        p."intermediary_address",
        ' --(tx ',
        LEFT(p."tx2_id", 5),
        '..)--> ',
        p."to_address"
    ) AS "path"
FROM
    paths p;