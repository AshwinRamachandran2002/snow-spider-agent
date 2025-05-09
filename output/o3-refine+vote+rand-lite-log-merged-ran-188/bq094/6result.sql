WITH small_dollar AS (
  -- Committees whose summed individual gifts are > $0 and < $200
  SELECT
    cmte_id,
    SUM(transaction_amt) AS small_dollar_sum
  FROM `bigquery-public-data.fec.individuals_2016`
  WHERE transaction_amt > 0         -- keep only positive gifts
    AND transaction_amt < 200       -- “small-dollar” definition
  GROUP BY cmte_id
  HAVING small_dollar_sum > 0       -- exclude committees that netted $0
     AND small_dollar_sum < 200     -- cap at $200 (exclusive)
),
supported AS (
  -- Committees that made ≥ 1 positive transfer to a candidate in 2016
  SELECT
    cmte_id,
    COUNT(DISTINCT cand_id)                    AS supported_candidate_cnt,
    STRING_AGG(DISTINCT name ORDER BY name)    AS supported_candidates
  FROM `bigquery-public-data.fec.committee_contributions_2016`
  WHERE transaction_amt > 0                    -- only positive support
  GROUP BY cmte_id
)
SELECT
  COALESCE(o.name, s.cmte_id)      AS committee_name,
  c.supported_candidate_cnt        AS num_candidates_supported,
  c.supported_candidates           AS candidates_supported_alpha,
  s.small_dollar_sum               AS total_small_dollar
FROM small_dollar AS s
JOIN supported   AS c  ON s.cmte_id = c.cmte_id      -- must have backed ≥1 candidate
LEFT JOIN (
  SELECT DISTINCT cmte_id, name
  FROM `bigquery-public-data.fec.other_committee_tx_2016`
) AS o           ON s.cmte_id = o.cmte_id            -- human-readable name if available
ORDER BY committee_name;