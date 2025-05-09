/*--------------------------------------------------------------
--  Committees with small-dollar (0-<200) individual donations
--  that also contributed to at least one candidate in 2016
--------------------------------------------------------------*/
WITH small_dollar AS (       
    SELECT  "cmte_id",
            SUM("transaction_amt") AS small_dollar_total
    FROM    FEC.FEC.INDIVIDUALS_2016
    WHERE   "transaction_amt" > 0          -- > $0
      AND   "transaction_amt" < 200        -- < $200
      AND   "cmte_id" IS NOT NULL
      AND   "cmte_id" ILIKE 'C%'           -- keep valid committee IDs
    GROUP BY "cmte_id"
    HAVING  SUM("transaction_amt") > 0
),    

supported AS (
    SELECT  cc."cmte_id",
            COUNT(DISTINCT cc."cand_id") AS num_unique_candidates,
            LISTAGG(DISTINCT cand."cand_name", ', ')
              WITHIN GROUP (ORDER BY cand."cand_name") AS candidate_names
    FROM    FEC.FEC.COMMITTEE_CONTRIBUTIONS_2016  cc
    LEFT JOIN FEC.FEC.CANDIDATE_2016              cand
           ON cc."cand_id" = cand."cand_id"
    GROUP BY cc."cmte_id"
),

names AS (
    SELECT  "cmte_id",
            MIN("cmte_nm") AS committee_name
    FROM    FEC.FEC.INDIV16_CM16
    WHERE   "cmte_id" IS NOT NULL
    GROUP BY "cmte_id"
)

SELECT  COALESCE(n.committee_name, sd."cmte_id") AS committee_name,
        s.num_unique_candidates,
        s.candidate_names,
        sd.small_dollar_total
FROM    small_dollar sd
JOIN    supported    s  ON sd."cmte_id" = s."cmte_id"
LEFT JOIN names      n  ON sd."cmte_id" = n."cmte_id"
ORDER BY committee_name;