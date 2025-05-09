/* Committees (2016 cycle) that
   1) supported at least one candidate, and
   2) received individual contributions >$0 and <$200
      (small‑dollar) whose aggregate total is >$0.

   Returned columns:
   committee_name,
   number_of_unique_candidates,
   candidate_names_alpha,
   small_dollar_contribution_total (4‑decimal precision)
*/
WITH small_donations AS (
  SELECT
    cmte_id,
    SUM(transaction_amt) AS small_dollar_total
  FROM `bigquery-public-data.fec.indiv16`
  WHERE transaction_amt > 0
    AND transaction_amt < 200
  GROUP BY cmte_id
  HAVING small_dollar_total > 0
),
committee_candidates AS (
  SELECT
    cc.cmte_id,
    COUNT(DISTINCT cc.cand_id) AS number_of_unique_candidates,
    STRING_AGG(
      DISTINCT IFNULL(cand.cand_name, 'UNKNOWN'),
      ', ' ORDER BY IFNULL(cand.cand_name, 'UNKNOWN')
    ) AS candidate_names_alpha
  FROM `bigquery-public-data.fec.candidate_committee_2016` AS cc
  LEFT JOIN `bigquery-public-data.fec.candidate_2016` AS cand
    ON cc.cand_id = cand.cand_id
  WHERE cc.fec_election_yr = 2016
  GROUP BY cc.cmte_id
)
SELECT
  COALESCE(cm.cmte_nm, sd.cmte_id)      AS committee_name,
  cc.number_of_unique_candidates,
  cc.candidate_names_alpha,
  FORMAT('%.4f', sd.small_dollar_total) AS small_dollar_contribution_total
FROM small_donations AS sd
JOIN committee_candidates AS cc
  ON sd.cmte_id = cc.cmte_id
LEFT JOIN `bigquery-public-data.fec.committee_2016` AS cm
  ON sd.cmte_id = cm.cmte_id
ORDER BY committee_name, cc.number_of_unique_candidates;