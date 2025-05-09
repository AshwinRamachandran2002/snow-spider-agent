SELECT
  REPLACE(cm.cmte_nm, '"', '')                                            AS committee_name,
  cand_info.num_candidates                                                AS number_of_unique_candidates,
  cand_info.candidate_names                                               AS candidate_names_alpha,
  ROUND(sd.small_dollar_total, 4)                                         AS small_dollar_contribution_total
FROM
  /* (1) committees that received > $0 in individual contributions ≤ $200 */
  (
    SELECT
      cmte_id,
      SUM(transaction_amt) AS small_dollar_total
    FROM `bigquery-public-data.fec.indiv16`
    WHERE transaction_amt > 0
      AND transaction_amt <= 200
    GROUP BY cmte_id
    HAVING SUM(transaction_amt) > 0
  ) sd
JOIN
  /* (2) 2016 committee‑candidate links with aggregated candidate info */
  (
    SELECT
      cc.cmte_id,
      COUNT(DISTINCT cc.cand_id)                                          AS num_candidates,
      STRING_AGG(REPLACE(c.cand_name, '"', ''), ', ' 
                 ORDER BY REPLACE(c.cand_name, '"', ''))                  AS candidate_names
    FROM `bigquery-public-data.fec.candidate_committee_2016` cc
    JOIN `bigquery-public-data.fec.candidate_2016`          c
      ON cc.cand_id = c.cand_id
    WHERE cc.fec_election_yr = 2016
    GROUP BY cc.cmte_id
  ) cand_info
ON sd.cmte_id = cand_info.cmte_id
JOIN `bigquery-public-data.fec.committee_2016` cm
  ON sd.cmte_id = cm.cmte_id
ORDER BY
  small_dollar_contribution_total DESC,
  committee_name;