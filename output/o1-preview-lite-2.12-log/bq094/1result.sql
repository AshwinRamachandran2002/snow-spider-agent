SELECT
  cm.cmte_nm AS committee_name,
  COUNT(DISTINCT cc.cand_id) AS number_of_supported_candidates,
  ARRAY_TO_STRING(
    ARRAY_AGG(DISTINCT cand.cand_name_clean ORDER BY cand.cand_name_clean),
    ', '
  ) AS supported_candidates,
  ROUND(sdc.total_small_dollar_donations, 4) AS total_small_dollar_donations
FROM
  (
    SELECT cmte_id, SUM(transaction_amt) AS total_small_dollar_donations
    FROM `bigquery-public-data.fec.individuals_2016`
    WHERE transaction_amt > 0 AND transaction_amt < 200
    GROUP BY cmte_id
  ) AS sdc
JOIN
  `bigquery-public-data.fec.committee_2016` AS cm
ON
  sdc.cmte_id = cm.cmte_id
JOIN
  `bigquery-public-data.fec.candidate_committee_2016` AS cc
ON
  cm.cmte_id = cc.cmte_id
JOIN
  (
    SELECT cand_id, REPLACE(cand_name, '"', '') AS cand_name_clean
    FROM `bigquery-public-data.fec.candidate_2016`
  ) AS cand
ON
  cc.cand_id = cand.cand_id
GROUP BY
  cm.cmte_nm,
  sdc.total_small_dollar_donations
ORDER BY
  cm.cmte_nm;