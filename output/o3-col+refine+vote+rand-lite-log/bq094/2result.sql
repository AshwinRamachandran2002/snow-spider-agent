-- Committees that (a) backed ≥1 candidate in 2016 and
-- (b) received >$0 but <$200 TOTAL in sub-$200 individual gifts.
WITH small_tot AS (              -- (b) committees’ small-dollar totals
  SELECT
    cmte_id,
    SUM(transaction_amt) AS small_sum
  FROM `bigquery-public-data.fec.individuals_2016`
  WHERE transaction_amt > 0          -- strictly more than $0
    AND transaction_amt < 200        -- strictly less than $200
  GROUP BY cmte_id
  HAVING small_sum > 0 AND small_sum < 200
),
cand_list AS (               -- (a) candidate counts & names per committee
  SELECT
    cmte_id,
    COUNT(DISTINCT cand_id) AS num_cand,
    STRING_AGG(
      DISTINCT name, ', ' ORDER BY name      -- alphabetical list
    ) AS cand_names
  FROM `bigquery-public-data.fec.committee_contributions_2016`
  WHERE cand_id IS NOT NULL                  -- ensure true support
  GROUP BY cmte_id
),
cmte_name AS (                -- human-readable committee name (fallback = id)
  SELECT
    cmte_id,
    ANY_VALUE(name) AS committee_name
  FROM `bigquery-public-data.fec.committee_contributions_2016`
  GROUP BY cmte_id
)
SELECT
  COALESCE(cn.committee_name, st.cmte_id) AS committee,
  cl.num_cand,
  cl.cand_names,
  st.small_sum
FROM small_tot st
JOIN cand_list cl ON st.cmte_id = cl.cmte_id   -- must satisfy both (a) & (b)
LEFT JOIN cmte_name cn ON st.cmte_id = cn.cmte_id
ORDER BY committee;