WITH small_dollar_contributions AS (
    SELECT
        i."cmte_id",
        SUM(i."transaction_amt") AS "Total_Sum_of_Small_Dollar_Donations"
    FROM FEC.FEC."INDIVIDUALS_2016" i
    WHERE i."entity_tp" = 'IND' AND i."transaction_amt" > 0 AND i."transaction_amt" < 200
    GROUP BY i."cmte_id"
    HAVING SUM(i."transaction_amt") > 0
)
SELECT
    c."cmte_nm" AS Committee_Name,
    COUNT(DISTINCT cc."cand_id") AS Number_of_Candidates_Supported,
    CAST(LISTAGG(DISTINCT cand."cand_name", ', ') WITHIN GROUP (ORDER BY cand."cand_name") AS VARCHAR) AS Candidate_Names_in_Alphabetic_Order,
    ROUND(sdc."Total_Sum_of_Small_Dollar_Donations", 4) AS Total_Sum_of_Small_Dollar_Donations
FROM
    small_dollar_contributions sdc
    INNER JOIN FEC.FEC."CANDIDATE_COMMITTEE_2016" cc ON sdc."cmte_id" = cc."cmte_id"
    INNER JOIN FEC.FEC."COMMITTEE_2016" c ON sdc."cmte_id" = c."cmte_id"
    INNER JOIN FEC.FEC."CANDIDATE_2016" cand ON cc."cand_id" = cand."cand_id"
GROUP BY
    c."cmte_nm", sdc."Total_Sum_of_Small_Dollar_Donations"
ORDER BY
    c."cmte_nm";