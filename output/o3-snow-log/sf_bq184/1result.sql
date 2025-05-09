WITH
/* 1. classify contract-creation traces by creator type */
creations AS (
    SELECT
        TO_DATE( TO_TIMESTAMP( "block_timestamp" / 1000000 ) ) AS "date",
        CASE
            WHEN "trace_address" IS NULL THEN 'external'   -- created by EOA
            ELSE 'contract'                                -- created by contract
        END                                                AS "creator_type"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "trace_type" = 'create'
),

/* 2. daily counts for each creator type */
daily AS (
    SELECT
        "date",
        SUM( CASE WHEN "creator_type" = 'external' THEN 1 ELSE 0 END ) AS "external_creations",
        SUM( CASE WHEN "creator_type" = 'contract' THEN 1 ELSE 0 END ) AS "contract_creations"
    FROM creations
    GROUP BY "date"
),

/* 3. calendar covering every day from 2017-01-01 to 2021-12-31
      (5 years = 1 826 days inclusive) */
calendar AS (
    SELECT
        DATEADD( 'day', seq4(), '2017-01-01' ) AS "date"
    FROM TABLE(
        GENERATOR( ROWCOUNT => 1826 )
    )
),

/* 4. merge calendar with daily counts, default missing days to zero */
daily_full AS (
    SELECT
        c."date",
        COALESCE(d."external_creations", 0) AS "external_creations",
        COALESCE(d."contract_creations", 0) AS "contract_creations"
    FROM calendar c
    LEFT JOIN daily d
      ON c."date" = d."date"
)

/* 5. cumulative totals */
SELECT
    "date",
    SUM("external_creations") OVER (ORDER BY "date"
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS "cumulative_external_creations",
    SUM("contract_creations")  OVER (ORDER BY "date"
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS "cumulative_contract_creations"
FROM daily_full
ORDER BY "date";