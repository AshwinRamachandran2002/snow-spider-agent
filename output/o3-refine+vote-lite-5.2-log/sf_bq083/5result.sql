WITH usdc_activity AS (
    SELECT
        /* 1.  Block date (UTC) */
        TO_DATE(TO_TIMESTAMP("block_timestamp" / 1e6))                                   AS "DATE",

        /* 2.  Direction:  +1 mint , -1 burn */
        CASE
            WHEN "input" ILIKE '0x40c10f19%' THEN  1
            WHEN "input" ILIKE '0x42966c68%' THEN -1
        END                                                                              AS "SIGN",

        /* 3.  32‑byte amount field in hex (drop leading 0x40c10f19 / 0x42966c68 headers) */
        CASE
            WHEN "input" ILIKE '0x40c10f19%' THEN SUBSTR("input", 75, 64)   -- mint: after fn‑id & address
            WHEN "input" ILIKE '0x42966c68%' THEN SUBSTR("input", 11, 64)   -- burn:  after fn‑id
        END                                                                              AS "AMT_HEX"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
    WHERE  LOWER("to_address") = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48'          -- USDC contract
      AND ("input" ILIKE '0x40c10f19%' OR "input" ILIKE '0x42966c68%')                 -- mint / burn calls
      AND YEAR(TO_TIMESTAMP("block_timestamp" / 1e6)) = 2023                           -- only year 2023
)

SELECT
    "DATE",
    /* 4.  Hex → decimal, scale (6 dec) and format in USD */
    TO_CHAR(
        SUM(
            "SIGN"
            * COALESCE(
                  TRY_TO_NUMBER(
                      CONCAT('0x', IFF(LTRIM("AMT_HEX",'0') = '', '0', LTRIM("AMT_HEX",'0'))), 16
                  ),
                  0
              ) / 1e6
        ),
        'FM$999,999,999,999,990.00'
    ) AS "Δ Total Market Value"
FROM usdc_activity
GROUP BY "DATE"
ORDER BY "DATE" DESC NULLS LAST;