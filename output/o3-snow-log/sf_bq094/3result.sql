/* Small-dollar (0 < amount < 200) individual-contribution committees, 2016 */

WITH small_dollar_tx AS (              -- each qualifying individual donation
    SELECT 
        "cmte_id",
        MAX("cmte_nm")           AS "committee_name",
        "cand_id",
        "transaction_amt"
    FROM FEC.FEC.INDIV16_CM16
    WHERE "transaction_amt" > 0          -- greater than $0
      AND "transaction_amt" < 200        -- less than $200
      AND "cand_id" IS NOT NULL          -- must be tied to a candidate
    GROUP BY "cmte_id", "cand_id", "transaction_amt"
),

committee_totals AS (                   -- total of small-dollar gifts per committee
    SELECT
        "cmte_id",
        "committee_name",
        SUM("transaction_amt") AS total_small_dollar
    FROM small_dollar_tx
    GROUP BY "cmte_id", "committee_name"
    HAVING SUM("transaction_amt") > 0    -- overall total must be > $0
       AND SUM("transaction_amt") < 200  -- and < $200
),

committee_candidates AS (               -- candidate names each committee supported
    SELECT
        sd."cmte_id",
        c."cand_name"
    FROM small_dollar_tx sd
    JOIN FEC.FEC.CANDIDATE_2016 c
      ON sd."cand_id" = c."cand_id"
),

candidate_lists AS (                    -- roll up candidate information
    SELECT
        "cmte_id",
        COUNT(DISTINCT "cand_name")                                                AS num_candidates,
        LISTAGG(DISTINCT "cand_name", ', ') WITHIN GROUP (ORDER BY "cand_name")    AS candidate_names
    FROM committee_candidates
    GROUP BY "cmte_id"
)

SELECT
    ct."committee_name",
    cl.num_candidates,
    cl.candidate_names,
    ct.total_small_dollar
FROM committee_totals ct
JOIN candidate_lists cl
  ON ct."cmte_id" = cl."cmte_id"
ORDER BY ct."committee_name";