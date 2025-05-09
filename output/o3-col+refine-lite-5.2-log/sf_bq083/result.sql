/*  Daily change in USDC market value (mint – burn) during 2023           */
/*  –  mints  : input starts with 0x40c10f19 (positive sign)              */
/*  –  burns  : input starts with 0x42966c68 (negative sign)              */
/*  –  amounts are read from the 32‑byte hex slot shown below, converted  */
/*     to whole USDC (‑6 decimals) and expressed in USD currency format   */

SELECT
    TO_CHAR(
        DATE_TRUNC(
            'day',
            TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)      -- µ‑s → seconds
        ),
        'YYYY-MM-DD'
    )                                            AS "date",

    /* format summed value as USD; FM keeps it tight, D/G add separators */
    TO_CHAR(
        SUM(
            CASE
                /*  mint(address,uint256) → amount in the **second** slot  */
                WHEN SUBSTR("input",1,10) = '0x40c10f19' THEN
                     COALESCE(
                         TRY_TO_NUMBER(
                             CONCAT(
                                 '0x',
                                 LTRIM(SUBSTR("input",75,64),'0')
                             ),
                             16                                     -- hex → number
                         ),
                     0) / 1e6                                       -- 6 decimals
                /*  burn(uint256) → amount in the **first** slot           */
                ELSE
                    - COALESCE(
                          TRY_TO_NUMBER(
                              CONCAT(
                                  '0x',
                                  LTRIM(SUBSTR("input",11,64),'0')
                              ),
                              16
                          ),
                      0) / 1e6
            END
        ),
        'FM$999,999,999,999,990.00'
    )                                            AS "Δ Total Market Value"
FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
WHERE "to_address" = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48'          -- USDC
  AND SUBSTR("input",1,10) IN ('0x40c10f19','0x42966c68')                  -- mint/burn
  AND "block_timestamp" BETWEEN 1672531200000000                           -- 2023‑01‑01 00:00 UTC
                             AND 1704067199000000                           -- 2023‑12‑31 23:59 UTC
GROUP BY 1
ORDER BY "date" DESC NULLS LAST;