/*  Committees that (1) backed ≥1 candidate in 2016
    and (2) received a positive but ≤ $200 total in sub-$200 individual gifts   */

WITH small_dollar_committees AS (
  SELECT
    cmte_id,
    SUM(transaction_amt) AS total_small_dollars
  FROM `bigquery-public-data.fec.individuals_2016`
  WHERE transaction_amt > 0            -- strictly more than $0
    AND transaction_amt <= 200         -- “small-dollar” upper bound
  GROUP BY cmte_id
  HAVING total_small_dollars > 0       -- keep only committees that actually got $
     AND total_small_dollars <= 200
),
committee_candidate_rollup AS (
  SELECT
    cmte_id,
    COUNT(DISTINCT cand_id)                         AS unique_candidates_supported,
    STRING_AGG(DISTINCT name, ', ' ORDER BY name)   AS candidates_supported_alpha
  FROM `bigquery-public-data.fec.committee_contributions_2016`
  GROUP BY cmte_id
  HAVING unique_candidates_supported > 0            -- backed at least one candidate
)

SELECT
  s.cmte_id                           AS committee_id_or_name,
  c.unique_candidates_supported,
  c.candidates_supported_alpha,
  s.total_small_dollars               AS total_small_dollar_amt
FROM small_dollar_committees AS s
JOIN committee_candidate_rollup AS c
  ON s.cmte_id = c.cmte_id
ORDER BY committee_id_or_name;