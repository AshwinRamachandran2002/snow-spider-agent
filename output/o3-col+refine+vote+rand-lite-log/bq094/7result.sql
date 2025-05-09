-- Committees that (1) backed ≥1 candidate in 2016 and
-- (2) received >0 in “small-dollar” individual contributions (0 < amt ≤ 200 USD).

WITH candidate_support AS (
  SELECT
    cmte_id,
    COUNT(DISTINCT cand_id)                                   AS num_candidates,
    STRING_AGG(DISTINCT name, ', ' ORDER BY name) AS candidate_names
  FROM `bigquery-public-data.fec.committee_contributions_2016`
  GROUP BY cmte_id
),

small_dollars AS (
  SELECT
    cmte_id,
    SUM(transaction_amt) AS small_dollar_total
  FROM `bigquery-public-data.fec.individuals_2016`
  WHERE transaction_amt > 0          -- strictly greater than $0
    AND transaction_amt <= 200       -- up to and including $200
  GROUP BY cmte_id
)

SELECT
  c.cmte_id                  AS committee_id,    -- committee “name” / identifier
  c.num_candidates,
  c.candidate_names,
  s.small_dollar_total
FROM candidate_support AS c
JOIN small_dollars   AS s
  ON c.cmte_id = s.cmte_id
WHERE s.small_dollar_total > 0
ORDER BY s.small_dollar_total DESC, committee_id;