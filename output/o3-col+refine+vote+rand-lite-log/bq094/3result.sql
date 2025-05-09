-- Committees that both supported at least one candidate in 2016
-- and received >$0 but <$200 individual contributions (summed >$0)
WITH candidates AS (
  SELECT
    cmte_id,
    ARRAY_AGG(DISTINCT name ORDER BY name) AS candidate_names
  FROM `bigquery-public-data.fec.committee_contributions_2016`
  GROUP BY cmte_id
),
small_dollars AS (
  SELECT
    cmte_id,
    SUM(transaction_amt) AS small_dollar_total
  FROM `bigquery-public-data.fec.individuals_2016`
  WHERE transaction_amt > 0        -- strictly greater than $0
    AND transaction_amt < 200      -- strictly less than $200
  GROUP BY cmte_id
  HAVING small_dollar_total > 0    -- keep only committees that actually received $
)
SELECT
  c.cmte_id                                         AS committee_id,         -- committee “name” (ID)
  ARRAY_LENGTH(c.candidate_names)                   AS num_unique_candidates_supported,
  ARRAY_TO_STRING(c.candidate_names, ', ')          AS candidates_supported_alpha,
  s.small_dollar_total                              AS total_small_dollar_received
FROM candidates      AS c
JOIN small_dollars   AS s
ON  c.cmte_id = s.cmte_id
ORDER BY total_small_dollar_received DESC;