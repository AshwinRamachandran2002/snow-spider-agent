WITH small_dollar_donations AS (
    SELECT "cmte_id",
           ROUND(SUM("transaction_amt"), 4) AS total_small_dollar_donations
    FROM FEC.FEC.INDIVIDUALS_2016
    WHERE "transaction_amt" > 0
      AND "transaction_amt" < 200
      AND "entity_tp" = 'IND'
    GROUP BY "cmte_id"
),
committee_candidates AS (
    SELECT cc."cmte_id",
           COUNT(DISTINCT cc."cand_id") AS number_of_supported_candidates,
           LISTAGG(cand."cand_name", ', ') WITHIN GROUP (ORDER BY cand."cand_name") AS candidates_names
    FROM FEC.FEC.CANDIDATE_COMMITTEE_2016 cc
    JOIN FEC.FEC.CANDIDATE_2016 cand
      ON cc."cand_id" = cand."cand_id"
    GROUP BY cc."cmte_id"
),
qualified_committees AS (
    SELECT sdd."cmte_id",
           sdd.total_small_dollar_donations,
           cc.number_of_supported_candidates,
           cc.candidates_names
    FROM small_dollar_donations sdd
    JOIN committee_candidates cc
      ON sdd."cmte_id" = cc."cmte_id"
),
final_output AS (
    SELECT REPLACE(CAST(c."cmte_nm" AS STRING), '"', '') AS committee_name,
           qc.number_of_supported_candidates,
           REPLACE(CAST(qc.candidates_names AS STRING), '"', '') AS candidates_names,
           qc.total_small_dollar_donations
    FROM qualified_committees qc
    JOIN FEC.FEC.COMMITTEE_2016 c
      ON qc."cmte_id" = c."cmte_id"
)
SELECT
    committee_name,
    number_of_supported_candidates,
    candidates_names,
    total_small_dollar_donations
FROM final_output
ORDER BY committee_name;