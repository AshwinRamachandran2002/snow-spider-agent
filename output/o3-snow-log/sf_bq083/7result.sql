WITH usdc_flows AS (
    SELECT
        /* calendar day (UTC) */
        DATE_TRUNC(
            'DAY',
            TO_TIMESTAMP("block_timestamp" / 1000000)
        )                                                    AS day,

        /* signed amount:  +mint  –burn  (scale from 6 dp) */
        (
            CASE
                WHEN SUBSTR("input", 1, 10) = '0x40c10f19'   /* mint */
                     THEN  1
                ELSE                                         /* burn */
                     -1
            END
            *
            /* take last 32-byte word of calldata → HEX → DEC */
            TRY_TO_DECIMAL(
                RIGHT(REPLACE("input", '0x', ''), 64),
                38, 0
            )
        ) / 1000000                                          AS delta_value
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
    WHERE "to_address" = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48'     -- USDC
      AND (
              "input" LIKE '0x40c10f19%'   /* mint */
           OR "input" LIKE '0x42966c68%'   /* burn */
          )
      AND DATE_TRUNC(
              'DAY',
              TO_TIMESTAMP("block_timestamp" / 1000000)
          ) BETWEEN '2023-01-01' AND '2023-12-31'
)

SELECT
    day,
    TO_CHAR(
        SUM(delta_value),
        'FM$999,999,999,999,990.00'
    ) AS "Δ Total Market Value"
FROM usdc_flows
GROUP BY day
ORDER BY day DESC NULLS LAST;