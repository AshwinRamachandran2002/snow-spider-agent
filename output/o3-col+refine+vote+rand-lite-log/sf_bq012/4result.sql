WITH
-- 1. Successful ETH transfers (exclude delegatecall, callcode, staticcall)
incoming AS (
  SELECT
    "to_address"                                     AS address,
    SUM("value")                                     AS in_wei
  FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
  WHERE "trace_type" = 'call'
    AND "status" = 1
    AND "to_address" IS NOT NULL
    AND ( "call_type" IS NULL
          OR "call_type" NOT IN ('delegatecall','callcode','staticcall') )
  GROUP BY "to_address"
),
outgoing AS (
  SELECT
    "from_address"                                   AS address,
    SUM("value")                                     AS out_wei
  FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRACES
  WHERE "trace_type" = 'call'
    AND "status" = 1
    AND "from_address" IS NOT NULL
    AND ( "call_type" IS NULL
          OR "call_type" NOT IN ('delegatecall','callcode','staticcall') )
  GROUP BY "from_address"
),

-- 2. Gas fees generated in each block
block_fees AS (
  SELECT
    "block_number",
    SUM("gas_price" * "receipt_gas_used")            AS total_gas_fee_wei
  FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS
  WHERE "gas_price" IS NOT NULL
    AND "receipt_gas_used" IS NOT NULL
  GROUP BY "block_number"
),

-- 3. Attribute block gas fees to the miner of that block
miner_rewards AS (
  SELECT
    b."miner"                                        AS address,
    SUM(f.total_gas_fee_wei)                         AS miner_fee_wei
  FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.BLOCKS  b
  JOIN block_fees f
    ON b."number" = f."block_number"
  WHERE b."miner" IS NOT NULL
  GROUP BY b."miner"
),

-- 4. Gas fees paid by each transaction sender
gas_fees AS (
  SELECT
    "from_address"                                   AS address,
    SUM("gas_price" * "receipt_gas_used")            AS gas_fee_wei
  FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TRANSACTIONS
  WHERE "from_address" IS NOT NULL
    AND "gas_price" IS NOT NULL
    AND "receipt_gas_used" IS NOT NULL
  GROUP BY "from_address"
),

-- 5. Combine all components to obtain net balance per address
combined AS (
  SELECT
    COALESCE(i.address, o.address, r.address, g.address)      AS address,
    COALESCE(i.in_wei,        0)  - 
    COALESCE(o.out_wei,       0)  + 
    COALESCE(r.miner_fee_wei, 0)  - 
    COALESCE(g.gas_fee_wei,   0)  AS net_balance_wei
  FROM incoming i
  FULL JOIN outgoing      o ON i.address = o.address
  FULL JOIN miner_rewards r ON COALESCE(i.address, o.address) = r.address
  FULL JOIN gas_fees      g ON COALESCE(i.address, o.address, r.address) = g.address
  WHERE COALESCE(i.address, o.address, r.address, g.address) IS NOT NULL
),

-- 6. Top-10 addresses by net balance
top10 AS (
  SELECT
    address,
    net_balance_wei
  FROM combined
  WHERE address IS NOT NULL
  ORDER BY net_balance_wei DESC NULLS LAST
  LIMIT 10
)

-- 7. Average of the Top-10 balances, expressed in quadrillions (10^15) and rounded
SELECT
  ROUND(AVG(net_balance_wei) / 1e15, 2)  AS "avg_top10_balance_quadrillions"
FROM top10;