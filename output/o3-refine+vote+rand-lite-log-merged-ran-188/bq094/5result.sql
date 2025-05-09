-- Committees that (a) backed ≥1 candidate in 2016 and
-- (b) collected >$0 and ≤$200 total in small-dollar individual gifts
WITH small_donations AS (
  SELECT
    cmte_id,
    SUM(transaction_amt) AS total_small_amt
  FROM `bigquery-public-data.fec.individuals_2016`
  WHERE transaction_amt > 0           -- only positive contributions
    AND transaction_amt <= 200        -- small-dollar threshold
  GROUP BY cmte_id
  HAVING total_small_amt > 0          -- must have taken in something
     AND total_small_amt <= 200       -- summed amount stays in small-dollar range
),
committee_support AS (
  SELECT
    cmte_id,
    ARRAY_AGG(DISTINCT name ORDER BY name) AS candidate_names
  FROM `bigquery-public-data.fec.committee_contributions_2016`
  GROUP BY cmte_id
)

SELECT
  sd.cmte_id                                        AS committee_name,
  ARRAY_LENGTH(cs.candidate_names)                  AS num_unique_candidates,
  ARRAY_TO_STRING(cs.candidate_names, ', ')         AS candidate_names_alphabetical,
  sd.total_small_amt                                AS total_small_donations
FROM small_donations sd
JOIN committee_support cs
ON sd.cmte_id = cs.cmte_id
ORDER BY committee_name;