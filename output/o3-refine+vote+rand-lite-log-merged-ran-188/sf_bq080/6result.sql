WITH
-- list of every calendar day between 2018‑08‑30 and 2018‑09‑30 (inclusive)
"DATES" AS (
    SELECT
        DATEADD(day, SEQ4(), '2018-08-30') AS "DAY"
    FROM TABLE(GENERATOR(ROWCOUNT => 32))          -- 32 days inclusive
),

-- contract‑creation traces in the period
"CREATIONS" AS (
    SELECT
        TO_DATE(TO_TIMESTAMP_NTZ("block_timestamp" / 1000000))               AS "DAY",
        CASE WHEN "trace_address" IS NULL THEN 1 ELSE 0 END                  AS "EXTERNAL_NEW",
        CASE WHEN "trace_address" IS NOT NULL THEN 1 ELSE 0 END              AS "CONTRACT_NEW"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "trace_type" = 'create'
      AND TO_DATE(TO_TIMESTAMP_NTZ("block_timestamp" / 1000000))
          BETWEEN '2018-08-30' AND '2018-09-30'
),

-- daily totals (including zero‑count days)
"DAILY_COUNTS" AS (
    SELECT
        d."DAY",
        COALESCE(SUM(c."EXTERNAL_NEW"), 0) AS "EXTERNAL_NEW",
        COALESCE(SUM(c."CONTRACT_NEW"), 0) AS "CONTRACT_NEW"
    FROM "DATES" d
    LEFT JOIN "CREATIONS" c
           ON c."DAY" = d."DAY"
    GROUP BY d."DAY"
),

-- cumulative running totals
"CUMULATIVE" AS (
    SELECT
        "DAY",
        SUM("EXTERNAL_NEW")  OVER (ORDER BY "DAY") AS "EXTERNAL_USER_CONTRACTS",
        SUM("CONTRACT_NEW")  OVER (ORDER BY "DAY") AS "CONTRACT_CREATED_BY_CONTRACTS"
    FROM "DAILY_COUNTS"
)

SELECT
    "DAY"   AS "DATE",
    "EXTERNAL_USER_CONTRACTS",
    "CONTRACT_CREATED_BY_CONTRACTS"
FROM "CUMULATIVE"
ORDER BY "DATE";