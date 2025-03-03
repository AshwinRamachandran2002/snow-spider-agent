SELECT
    com.cmte_nm AS Committee_Name,
    COUNT(DISTINCT cand.cand_id) AS Number_of_Candidates_Supported,
    STRING_AGG(
        DISTINCT REPLACE(cand.cand_name, '"', '') 
        ORDER BY REPLACE(cand.cand_name, '"', '')
    ) AS Candidate_Names,
    ROUND(donations.total_small_dollar_donations, 4) AS Total_Small_Dollar_Donations
FROM (
    SELECT cmte_id, SUM(transaction_amt) AS total_small_dollar_donations
    FROM `bigquery-public-data.fec.individuals_2016`
    WHERE transaction_amt > 0 AND transaction_amt < 200
      AND EXTRACT(YEAR FROM transaction_dt) BETWEEN 2015 AND 2016
    GROUP BY cmte_id
    HAVING SUM(transaction_amt) > 0 AND SUM(transaction_amt) < 200
) AS donations
JOIN `bigquery-public-data.fec.committee_2016` AS com
    ON donations.cmte_id = com.cmte_id
JOIN `bigquery-public-data.fec.candidate_committee_2016` AS cc
    ON com.cmte_id = cc.cmte_id
JOIN `bigquery-public-data.fec.candidate_2016` AS cand
    ON cc.cand_id = cand.cand_id
WHERE cand.cand_election_yr = 2016
GROUP BY
    com.cmte_nm,
    donations.total_small_dollar_donations