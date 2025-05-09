/*  Committees in the 2016 cycle that …                                         *
 *  • received individual contributions >0 and ≤200 USD, and                    *
 *  • contributed to at least one candidate.                                    *
 *                                                                              *
 *  Output: committee ID (used here as the name),                               *
 *          number of unique candidates backed,                                 *
 *          alphabetical list of those candidates’ committee names,             *
 *          total small-dollar receipts.                                        */
WITH small_dollars AS (          -- committees with qualifying individual money
  SELECT
    cmte_id,
    SUM(transaction_amt) AS small_dollar_total
  FROM `bigquery-public-data.fec.individuals_2016`
  WHERE transaction_amt > 0
    AND transaction_amt <= 200
  GROUP BY cmte_id
  HAVING SUM(transaction_amt) > 0
),
committee_to_candidate AS (      -- committee-to-candidate disbursements
  SELECT
    cmte_id,
    cand_id
  FROM `bigquery-public-data.fec.committee_contributions_2016`
  WHERE cand_id IS NOT NULL
),
cand_names AS (                  -- quick lookup of a readable name per cand_id
  SELECT
    cand_id,
    ANY_VALUE(name) AS cand_name            -- name of the recipient committee
  FROM `bigquery-public-data.fec.committee_contributions_2016`
  WHERE cand_id IS NOT NULL
  GROUP BY cand_id
),
qualified AS (                   -- committees meeting both requirements
  SELECT
    sd.cmte_id,
    sd.small_dollar_total,
    ctc.cand_id
  FROM small_dollars          AS sd
  JOIN committee_to_candidate AS ctc
    ON sd.cmte_id = ctc.cmte_id
)
SELECT
  q.cmte_id                                                         AS committee_name,
  COUNT(DISTINCT q.cand_id)                                         AS num_candidates_supported,
  ARRAY_TO_STRING(
      ARRAY_AGG(DISTINCT cn.cand_name ORDER BY cn.cand_name), ', '
  )                                                                 AS candidate_names,
  ROUND(MAX(q.small_dollar_total), 4)                               AS total_small_dollar_donations
FROM qualified AS q
LEFT JOIN cand_names AS cn
       ON q.cand_id = cn.cand_id
GROUP BY q.cmte_id
ORDER BY total_small_dollar_donations DESC;