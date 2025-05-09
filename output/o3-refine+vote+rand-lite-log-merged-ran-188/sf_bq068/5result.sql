WITH time_window AS (   -- required period
    SELECT
        DATE_PART(EPOCH_MICROSECOND,
                  TO_TIMESTAMP_NTZ('2014-03-01 00:00:00')) AS start_ts ,
        DATE_PART(EPOCH_MICROSECOND,
                  TO_TIMESTAMP_NTZ('2014-04-01 00:00:00')) AS end_ts
),

/* ------------------------------------------------------------------
   Double‑entry journal   (+ outputs   /  – inputs)
------------------------------------------------------------------ */
journal AS (

    /* credits -------------------------------------------------------- */
    SELECT
        flt.value::TEXT                    AS address ,
        O."type"                           AS address_type ,
        O."value"::NUMBER                  AS amount        -- positive
    FROM CRYPTO.CRYPTO_BITCOIN_CASH."OUTPUTS"  O
         , LATERAL FLATTEN( INPUT => O."addresses") flt
         , time_window tw
    WHERE O."block_timestamp" >= tw.start_ts
      AND O."block_timestamp" <  tw.end_ts

    UNION ALL

    /* debits --------------------------------------------------------- */
    SELECT
        flt.value::TEXT                    AS address ,
        I."type"                           AS address_type ,
       -I."value"::NUMBER                  AS amount        -- negative
    FROM CRYPTO.CRYPTO_BITCOIN_CASH."INPUTS"   I
         , LATERAL FLATTEN( INPUT => I."addresses") flt
         , time_window tw
    WHERE I."block_timestamp" >= tw.start_ts
      AND I."block_timestamp" <  tw.end_ts
),

/* ------------------------------------------------------------------
   Final balance for each address within the window
------------------------------------------------------------------ */
address_balances AS (
    SELECT
        address_type ,
        address ,
        SUM(amount) AS final_balance
    FROM journal
    GROUP BY address_type , address
)

/* ------------------------------------------------------------------
   Maximum & minimum final balances by address type
------------------------------------------------------------------ */
SELECT
    address_type ,
    MAX(final_balance) AS max_final_balance ,
    MIN(final_balance) AS min_final_balance
FROM address_balances
GROUP BY address_type
ORDER BY address_type;