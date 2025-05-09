WITH date_series AS (   -- one row per calendar day (inclusive)
    SELECT
        DATEADD(day, seq4(), TO_DATE('2018-08-30')) AS dt
    FROM TABLE(
        GENERATOR(ROWCOUNT => 32)                   -- 32 days: 30-Aug-2018 … 30-Sep-2018
    )
),

creations AS (          -- successful contract-creation traces in that range
    SELECT
        TO_DATE(TO_TIMESTAMP("block_timestamp", 6))                            AS dt,   -- micro-seconds epoch
        CASE                                                                  -- created directly by EOA
            WHEN "trace_address" IS NULL OR TRIM("trace_address") IN ('', '0')
            THEN 1 ELSE 0
        END  AS external_flag,
        CASE                                                                  -- created by another contract
            WHEN "trace_address" IS NOT NULL AND TRIM("trace_address") NOT IN ('', '0')
            THEN 1 ELSE 0
        END  AS contract_flag
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "trace_type" IN ('create', 'create2')
      AND "status" = 1
      AND TO_DATE(TO_TIMESTAMP("block_timestamp", 6))
          BETWEEN '2018-08-30' AND '2018-09-30'
),

daily AS (              -- new contracts per calendar day
    SELECT
        dt,
        SUM(external_flag)  AS external_cnt,
        SUM(contract_flag)  AS contract_cnt
    FROM creations
    GROUP BY dt
),

combined AS (           -- ensure every date appears
    SELECT
        ds.dt,
        COALESCE(d.external_cnt, 0) AS external_cnt,
        COALESCE(d.contract_cnt, 0) AS contract_cnt
    FROM date_series ds
    LEFT JOIN daily d ON ds.dt = d.dt
),

cumulative AS (         -- cumulative totals
    SELECT
        dt                                                     AS "DATE",
        SUM(external_cnt)  OVER (ORDER BY dt)
            AS "EXTERNAL_USERS_CONTRACTS_CUMULATIVE",
        SUM(contract_cnt)  OVER (ORDER BY dt)
            AS "CONTRACTS_CREATED_BY_CONTRACTS_CUMULATIVE"
    FROM combined
)

SELECT *
FROM cumulative
ORDER BY "DATE";