/*  Highest and lowest Dash balances for April-2023  */
WITH
/* ------------------------------------------------------------------ */
/* 1. All Dash blocks in April-2023                                   */
/* ------------------------------------------------------------------ */
blocks_month AS (
    SELECT  "number"
    FROM    CRYPTO.CRYPTO_DASH."BLOCKS"
    WHERE   "timestamp_month" = '2023-04-01'
),

/* ------------------------------------------------------------------ */
/* 2. Prepare OUTPUT rows (credits = +value)                          */
/*    – build one string address per row by concatenating             */
/*      every element in the "addresses" array                        */
/* ------------------------------------------------------------------ */
outputs_pre AS (
    SELECT
        o."block_number",
        o."type"                                                    AS addr_type,
        /* build comma-separated address string */
        LISTAGG(f.value::STRING , ',') WITHIN GROUP (ORDER BY f.index) 
                                                                  AS address,
        CAST(o."value" AS NUMBER)                                   AS amt
    FROM    CRYPTO.CRYPTO_DASH."OUTPUTS" o
            JOIN blocks_month b
              ON o."block_number" = b."number"
            ,  LATERAL FLATTEN ( INPUT => o."addresses") f
    GROUP   BY o."block_number", o."type", o."value"
),

/* ------------------------------------------------------------------ */
/* 3. Prepare INPUT rows (debits = –value)                            */
/* ------------------------------------------------------------------ */
inputs_pre AS (
    SELECT
        i."block_number",
        i."type"                                                    AS addr_type,
        LISTAGG(f.value::STRING , ',') WITHIN GROUP (ORDER BY f.index) 
                                                                  AS address,
        -CAST(i."value" AS NUMBER)                                  AS amt  -- negative
    FROM    CRYPTO.CRYPTO_DASH."INPUTS"  i
            JOIN blocks_month b
              ON i."block_number" = b."number"
            ,  LATERAL FLATTEN ( INPUT => i."addresses") f
    GROUP   BY i."block_number", i."type", i."value"
),

/* ------------------------------------------------------------------ */
/* 4. Combine credits & debits, then sum to get balance per address   */
/* ------------------------------------------------------------------ */
balances AS (
    SELECT   address,
             addr_type,
             SUM(amt) AS balance
    FROM    (
             SELECT * FROM outputs_pre
             UNION ALL
             SELECT * FROM inputs_pre
            )
    WHERE    address IS NOT NULL
    GROUP BY address, addr_type
),

/* ------------------------------------------------------------------ */
/* 5. Rank balances to find highest and lowest                       */
/* ------------------------------------------------------------------ */
ranked AS (
    SELECT  address,
            addr_type,
            balance,
            RANK() OVER(ORDER BY balance DESC) AS r_high,
            RANK() OVER(ORDER BY balance ASC)  AS r_low
    FROM    balances
)

/* ------------------------------------------------------------------ */
/* 6. Final result                                                    */
/* ------------------------------------------------------------------ */
SELECT  'HIGHEST' AS category,
        address,
        addr_type,
        balance
FROM    ranked
WHERE   r_high = 1

UNION ALL

SELECT  'LOWEST'  AS category,
        address,
        addr_type,
        balance
FROM    ranked
WHERE   r_low = 1;