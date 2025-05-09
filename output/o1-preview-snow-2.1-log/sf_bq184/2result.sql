WITH dates AS (
  SELECT DATEADD(day, ROW_NUMBER() OVER (ORDER BY NULL) - 1, DATE '2017-01-01') AS dt
  FROM (
    SELECT 1 FROM TABLE(GENERATOR(ROWCOUNT => 1826))
  )
),
contracts_by_users AS (
  SELECT DATE_TRUNC('day', TO_TIMESTAMP("block_timestamp" / 1e6)) AS dt,
         COUNT(*) AS contracts_created_by_users
  FROM "CRYPTO"."CRYPTO_ETHEREUM"."TRANSACTIONS"
  WHERE "to_address" IS NULL
    AND "block_timestamp" IS NOT NULL
    AND DATE_TRUNC('day', TO_TIMESTAMP("block_timestamp" / 1e6)) BETWEEN '2017-01-01' AND '2021-12-31'
  GROUP BY dt
),
contracts_by_contracts AS (
  SELECT DATE_TRUNC('day', TO_TIMESTAMP("block_timestamp" / 1e6)) AS dt,
         COUNT(*) AS contracts_created_by_contracts
  FROM "CRYPTO"."CRYPTO_ETHEREUM"."TRACES"
  WHERE "trace_type" = 'create'
    AND "block_timestamp" IS NOT NULL
    AND DATE_TRUNC('day', TO_TIMESTAMP("block_timestamp" / 1e6)) BETWEEN '2017-01-01' AND '2021-12-31'
  GROUP BY dt
),
daily_counts AS (
  SELECT dates.dt,
         COALESCE(uc.contracts_created_by_users, 0) AS contracts_created_by_users,
         COALESCE(cc.contracts_created_by_contracts, 0) AS contracts_created_by_contracts
  FROM dates
  LEFT JOIN contracts_by_users uc ON dates.dt = uc.dt
  LEFT JOIN contracts_by_contracts cc ON dates.dt = cc.dt
)
SELECT TO_CHAR(dt, 'YYYY-MM-DD') AS "Date",
       SUM(contracts_created_by_users) OVER (ORDER BY dt) AS "Cumulative_Contracts_Created_by_Users",
       SUM(contracts_created_by_contracts) OVER (ORDER BY dt) AS "Cumulative_Contracts_Created_by_Contracts"
FROM daily_counts
ORDER BY dt;