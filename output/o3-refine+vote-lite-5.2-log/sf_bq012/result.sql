WITH
/* ------------------------------------------------------------------ */
/* 1. Ether value transfers extracted from successful traces           */
/*    (exclude delegatecall / callcode / staticcall)                  */
/* ------------------------------------------------------------------ */
trace_transfers AS (

    /* incoming (+) */
    SELECT
        LOWER("to_address")         AS address ,
        SUM("value")                AS amount
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE "status"    = 1
      AND "trace_type" = 'call'
      AND ( "call_type" IS NULL
            OR LOWER("call_type") NOT IN ('delegatecall','callcode','staticcall') )
      AND "value"      > 0
      AND "to_address" IS NOT NULL
    GROUP BY 1

    UNION ALL

    /* outgoing (–) */
    SELECT
        LOWER("from_address")       AS address ,
       -SUM("value")                AS amount
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
    WHERE "status"    = 1
      AND "trace_type" = 'call'
      AND ( "call_type" IS NULL
            OR LOWER("call_type") NOT IN ('delegatecall','callcode','staticcall') )
      AND "value"       > 0
      AND "from_address" IS NOT NULL
    GROUP BY 1
),

/* ------------------------------------------------------------------ */
/* 2. Gas‑fee data per transaction                                    */
/* ------------------------------------------------------------------ */
tx_fees AS (
    SELECT
        "block_number",
        LOWER("from_address")                         AS from_addr ,
        ("gas_price" * "receipt_gas_used")            AS fee
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS
    WHERE "gas_price" IS NOT NULL
      AND "receipt_gas_used" IS NOT NULL
),

/* ------------------------------------------------------------------ */
/* 3. Miner rewards (+)   and sender gas deductions (–)               */
/* ------------------------------------------------------------------ */
fee_movements AS (

    /* credit total gas fees of a block to its miner */
    SELECT
        LOWER(b."miner")        AS address ,
        SUM(f.fee)              AS amount
    FROM tx_fees  f
    JOIN ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.BLOCKS b
          ON f."block_number" = b."number"
    GROUP BY 1

    UNION ALL

    /* debit gas fees from senders */
    SELECT
        from_addr               AS address ,
       -SUM(fee)                AS amount
    FROM tx_fees
    GROUP BY 1
),

/* ------------------------------------------------------------------ */
/* 4. Combine every movement                                           */
/* ------------------------------------------------------------------ */
all_movements AS (
    SELECT * FROM trace_transfers
    UNION ALL
    SELECT * FROM fee_movements
),

/* ------------------------------------------------------------------ */
/* 5. Net balance per address                                          */
/* ------------------------------------------------------------------ */
balances AS (
    SELECT
        address,
        SUM(amount) AS balance
    FROM all_movements
    WHERE address IS NOT NULL
      AND address <> '0x0000000000000000000000000000000000000000'
    GROUP BY address
),

/* ------------------------------------------------------------------ */
/* 6. Top‑10 addresses by balance                                      */
/* ------------------------------------------------------------------ */
top10 AS (
    SELECT
        address,
        balance
    FROM balances
    ORDER BY balance DESC NULLS LAST, address
    LIMIT 10
)

/* ------------------------------------------------------------------ */
/* 7. Average balance (in quadrillions, 10^15)                         */
/* ------------------------------------------------------------------ */
SELECT
    ROUND( AVG( balance / POWER(10,15) ) , 2)  AS "AVERAGE_BALANCE_QUADRILLIONS"
FROM top10;