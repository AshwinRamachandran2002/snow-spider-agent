/*------------------------------------------------------------------
  Committees (2016) that:
     • supported ≥ 1 candidate, and
     • received a total of > $0 and < $200 in small-dollar
       individual contributions
------------------------------------------------------------------*/
WITH small_indiv AS (      -- 1. committee-level sum of 0–200 donations
    SELECT
        "cmte_id"                AS cmte_id,
        SUM("transaction_amt")   AS small_dollar_sum
    FROM FEC.FEC.INDIVIDUALS_2016
    WHERE "transaction_amt" > 0
      AND "transaction_amt" < 200          -- strictly between 0 & 200
    GROUP BY "cmte_id"
),
cmte_support AS (          -- 2. committees that backed at least one candidate
    SELECT
        "cmte_id"  AS cmte_id,
        "cand_id"  AS cand_id
    FROM FEC.FEC.COMMITTEE_CONTRIBUTIONS_2016
    WHERE "cand_id" IS NOT NULL
),
cand_names AS (            -- 3. candidate-ID → name
    SELECT
        "cand_id"   AS cand_id,
        "cand_name" AS cand_name
    FROM FEC.FEC.CANDIDATE_2016
),
comm_names AS (            -- 4. best-effort committee name lookup
    SELECT
        "cand_pcc"              AS cmte_id,
        MIN("cand_name")        AS committee_name
    FROM FEC.FEC.CANDIDATE_2016
    WHERE "cand_pcc" IS NOT NULL
    GROUP BY "cand_pcc"
)

SELECT
    COALESCE(comm_names.committee_name, cmte.cmte_id)                           AS "COMMITTEE_NAME",
    COUNT(DISTINCT cmte.cand_id)                                                AS "NUM_UNIQUE_CANDIDATES",
    LISTAGG(DISTINCT cand_names.cand_name, ', ')
        WITHIN GROUP (ORDER BY cand_names.cand_name)                            AS "CANDIDATES_SUPPORTED",
    small.small_dollar_sum                                                      AS "TOTAL_SMALL_DOLLAR_DONATIONS"
FROM cmte_support              cmte
JOIN small_indiv               small  ON cmte.cmte_id = small.cmte_id
LEFT JOIN cand_names           ON cmte.cand_id = cand_names.cand_id
LEFT JOIN comm_names           ON cmte.cmte_id = comm_names.cmte_id
GROUP BY
    COALESCE(comm_names.committee_name, cmte.cmte_id),
    small.small_dollar_sum
HAVING
    small.small_dollar_sum > 0         -- must have at least some small $
ORDER BY
    small.small_dollar_sum DESC NULLS LAST;