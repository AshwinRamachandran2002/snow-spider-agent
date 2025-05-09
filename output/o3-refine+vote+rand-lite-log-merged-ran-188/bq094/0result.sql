/*  Committees that in the 2016 cycle …
    1) gave money to at least one candidate (i.e., appear in committee_contributions_2016)
    2) received >$0 but <$200 individual contributions whose total is >$0            */

WITH small AS (
  SELECT
    cmte_id,
    SUM(transaction_amt) AS small_dollar_total
  FROM `bigquery-public-data.fec.individuals_2016`
  WHERE transaction_amt > 0
    AND transaction_amt < 200
    AND REGEXP_CONTAINS(cmte_id, r'^C\d{8}')            -- keep well-formed committee IDs
  GROUP BY cmte_id
  HAVING small_dollar_total > 0                         -- must have >$0 in qualifying gifts
),
cand AS (
  SELECT
    cmte_id,
    ARRAY_AGG(DISTINCT name ORDER BY name) AS cand_names -- names of candidate committees supported
  FROM `bigquery-public-data.fec.committee_contributions_2016`
  GROUP BY cmte_id
)

SELECT
  s.cmte_id                                   AS committee_id,      -- committee “name” (ID)
  ARRAY_LENGTH(c.cand_names)                  AS num_unique_candidates,
  ARRAY_TO_STRING(c.cand_names, ', ')         AS candidate_names_alphabetical,
  s.small_dollar_total                        AS total_small_dollar_received
FROM small AS s
JOIN cand  AS c
ON  s.cmte_id = c.cmte_id                     -- only committees that meet both criteria
ORDER BY committee_id;