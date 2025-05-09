SELECT 
  c.cmte_nm AS committee_name,
  COUNT(DISTINCT cc.cand_id) AS number_of_supported_candidates,
  STRING_AGG(DISTINCT cand.cand_name_replaced, ', ' ORDER BY cand.cand_name_replaced ASC) AS supported_candidates,
  ROUND(SUM(i.transaction_amt), 4) AS total_small_dollar_donations
FROM `bigquery-public-data.fec.committee_2016` c
JOIN `bigquery-public-data.fec.candidate_committee_2016` cc
  ON c.cmte_id = cc.cmte_id
JOIN (
    SELECT cand_id, REPLACE(cand_name, '"', '') AS cand_name_replaced
    FROM `bigquery-public-data.fec.candidate_2016`
) cand
  ON cc.cand_id = cand.cand_id
JOIN `bigquery-public-data.fec.individuals_2016` i
  ON c.cmte_id = i.cmte_id
WHERE i.transaction_amt > 0 AND i.transaction_amt < 200
GROUP BY c.cmte_nm