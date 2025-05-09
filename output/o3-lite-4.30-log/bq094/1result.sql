SELECT
  com.cmte_nm                                                       AS committee_name,
  COUNT(DISTINCT cc.cand_id)                                        AS number_of_unique_candidates,
  STRING_AGG(DISTINCT cand.cand_name, ', ' ORDER BY cand.cand_name) AS candidate_names_alpha,
  ROUND(SUM(ind.transaction_amt), 4)                                AS small_dollar_contribution_total
FROM `bigquery-public-data.fec.indiv16`               AS ind
JOIN `bigquery-public-data.fec.candidate_committee_2016` AS cc
     ON ind.cmte_id = cc.cmte_id
JOIN `bigquery-public-data.fec.committee_2016`         AS com
     ON cc.cmte_id = com.cmte_id
JOIN `bigquery-public-data.fec.candidate_2016`         AS cand
     ON cc.cand_id = cand.cand_id
WHERE
      cc.fec_election_yr = 2016
  AND ind.transaction_amt > 0 
  AND ind.transaction_amt < 200
GROUP BY
  com.cmte_nm
HAVING
  SUM(ind.transaction_amt) > 0
ORDER BY
  small_dollar_contribution_total DESC,
  committee_name;