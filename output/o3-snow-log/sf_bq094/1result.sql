WITH "small_indiv" AS (      -- committees whose individual gifts are >$0 and <$200 in total
    SELECT 
        "cmte_id",
        SUM("transaction_amt")            AS "small_dollar_total"
    FROM "FEC"."FEC"."INDIVIDUALS_2016"
    WHERE "transaction_amt" > 0
      AND "transaction_amt" < 200
    GROUP BY "cmte_id"
    HAVING SUM("transaction_amt") > 0      -- overall > $0
       AND SUM("transaction_amt") < 200    -- overall < $200
),

"committee_candidates" AS (   -- committees that gave to at least one candidate
    SELECT
        cc."cmte_id",
        COUNT(DISTINCT cc."cand_id")                                                   AS "num_candidates",
        LISTAGG(DISTINCT c."cand_name", ', ') WITHIN GROUP (ORDER BY c."cand_name")    AS "candidate_names"
    FROM "FEC"."FEC"."COMMITTEE_CONTRIBUTIONS_2016"  cc
    JOIN "FEC"."FEC"."CANDIDATE_2016"                c
      ON cc."cand_id" = c."cand_id"
    GROUP BY cc."cmte_id"
),

"committee_names" AS (        -- try to derive a readable committee name
    SELECT 
        "cand_pcc"                           AS "cmte_id",
        MIN("cand_name")                     AS "committee_name"
    FROM "FEC"."FEC"."CANDIDATE_2016"
    GROUP BY "cand_pcc"
)

SELECT 
    COALESCE(cn."committee_name", si."cmte_id")   AS "committee_name",
    cc."num_candidates",
    cc."candidate_names",
    ROUND(si."small_dollar_total", 4)             AS "total_small_dollar_donations"
FROM       "small_indiv"          si
JOIN       "committee_candidates" cc  ON si."cmte_id" = cc."cmte_id"
LEFT JOIN  "committee_names"      cn  ON si."cmte_id" = cn."cmte_id"
ORDER BY    "committee_name" NULLS LAST;