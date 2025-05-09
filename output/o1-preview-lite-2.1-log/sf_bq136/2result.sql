WITH
initial_tx AS (
    SELECT
        "id" AS "initial_tx_id",
        "to_addr" AS "intermediate_address"
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE "sender" = 'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz'
),
intermediary_tx_counts AS (
    SELECT
        "sender" AS "intermediate_address",
        COUNT(*) AS "outgoing_tx_count"
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    GROUP BY "sender"
),
filtered_intermediaries AS (
    SELECT
        i."intermediate_address",
        i."initial_tx_id"
    FROM initial_tx i
    JOIN intermediary_tx_counts c
        ON i."intermediate_address" = c."intermediate_address"
    WHERE c."outgoing_tx_count" <= 50
),
second_tx AS (
    SELECT
        "id" AS "second_tx_id",
        "sender" AS "intermediate_address"
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE "to_addr" = 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
)
SELECT
    'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz' AS "from_address",
    CONCAT(
        'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz',
        ' --(tx ', SUBSTRING(fi."initial_tx_id", 1, 5), '..)--> ',
        fi."intermediate_address",
        ' --(tx ', SUBSTRING(st."second_tx_id", 1, 5), '..)--> ',
        'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
    ) AS "path"
FROM filtered_intermediaries fi
JOIN second_tx st
    ON fi."intermediate_address" = st."intermediate_address";