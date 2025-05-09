WITH small_donations AS (
    SELECT
        "cmte_id",
        SUM("transaction_amt") AS "Total_Sum_of_Small_Dollar_Donations"
    FROM FEC.FEC.INDIVIDUALS_2016
    WHERE "transaction_amt" > 0 AND "transaction_amt" < 200
    GROUP BY "cmte_id"
    HAVING SUM("transaction_amt") > 0 AND SUM("transaction_amt") < 200
)
SELECT
    c."cmte_nm" AS "Committee_Name",
    COUNT(DISTINCT cc."cand_id") AS "Number_of_Candidates_Supported",
    LISTAGG(DISTINCT cd."cand_name", ', ') WITHIN GROUP (ORDER BY cd."cand_name") AS "Candidate_Names_in_Alphabetic_Order",
    CAST(sd."Total_Sum_of_Small_Dollar_Donations" AS FLOAT) AS "Total_Sum_of_Small_Dollar_Donations"
FROM small_donations sd
JOIN FEC.FEC.COMMITTEE_2016 c ON sd."cmte_id" = c."cmte_id"
JOIN FEC.FEC.CANDIDATE_COMMITTEE_2016 cc ON sd."cmte_id" = cc."cmte_id"
JOIN FEC.FEC.CANDIDATE_2016 cd ON cc."cand_id" = cd."cand_id"
GROUP BY c."cmte_nm", sd."Total_Sum_of_Small_Dollar_Donations"
ORDER BY c."cmte_nm";