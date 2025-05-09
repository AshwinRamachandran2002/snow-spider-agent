SELECT c."cmte_nm" AS Committee_Name,
       CAST(n."num_candidates" AS STRING) AS Number_of_Candidates_Supported,
       n."candidate_names" AS Candidate_Names_in_Alphabetic_Order,
       CAST(ROUND(s."total_small_dollar", 4) AS STRING) AS Total_Sum_of_Small_Dollar_Donations
FROM (
  SELECT "cmte_id", SUM("transaction_amt") AS "total_small_dollar"
  FROM "FEC"."FEC"."INDIVIDUALS_2016"
  WHERE "transaction_amt" > 0 AND "transaction_amt" < 200
  GROUP BY "cmte_id"
) s
JOIN (
  SELECT cc."cmte_id",
         COUNT(DISTINCT cc."cand_id") AS "num_candidates",
         LISTAGG(DISTINCT ca."cand_name", ', ') WITHIN GROUP (ORDER BY ca."cand_name") AS "candidate_names"
      FROM "FEC"."FEC"."CANDIDATE_COMMITTEE_2016" cc
      JOIN "FEC"."FEC"."CANDIDATE_2016" ca ON cc."cand_id" = ca."cand_id"
      GROUP BY cc."cmte_id"
) n ON s."cmte_id" = n."cmte_id"
JOIN "FEC"."FEC"."COMMITTEE_2016" c ON s."cmte_id" = c."cmte_id"
ORDER BY c."cmte_nm";