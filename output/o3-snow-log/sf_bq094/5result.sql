/* Committees in the 2016 cycle that
   1) made at least one contribution to a candidate, and
   2) received total individual contributions >$0 and <$200
*/
WITH small_indiv AS (          -- small-dollar individual contributions
    SELECT
        "cmte_id",
        SUM("transaction_amt") AS total_small_amt
    FROM FEC.FEC.INDIVIDUALS_2016
    WHERE "transaction_amt" > 0
      AND "transaction_amt" < 200
    GROUP BY "cmte_id"
    HAVING SUM("transaction_amt") > 0
),

cmte_cands AS (                -- committees that supported candidates
    SELECT
        "cmte_id",
        "cand_id"
    FROM FEC.FEC.COMMITTEE_CONTRIBUTIONS_2016
    WHERE "cand_id" IS NOT NULL
),

qualified AS (                 -- committees satisfying both rules
    SELECT DISTINCT
        s."cmte_id",
        s.total_small_amt
    FROM small_indiv s
    JOIN cmte_cands c
      ON s."cmte_id" = c."cmte_id"
),

cmte_names AS (                -- committee names
    SELECT
        "cmte_id",
        MAX("cmte_nm") AS cmte_nm
    FROM FEC.FEC.INDIV16_CM16
    GROUP BY "cmte_id"
)

SELECT
    COALESCE(n.cmte_nm, q."cmte_id")                                AS "committee_name",
    COUNT(DISTINCT cand."cand_id")                                   AS "num_unique_candidates",
    LISTAGG(DISTINCT cand."cand_name", ', ')
        WITHIN GROUP (ORDER BY cand."cand_name")                     AS "candidate_names_alpha",
    q.total_small_amt                                                AS "total_small_dollar_donations"
FROM qualified              q
JOIN cmte_cands             cc   ON q."cmte_id" = cc."cmte_id"
JOIN FEC.FEC.CANDIDATE_2016 cand ON cand."cand_id" = cc."cand_id"
LEFT JOIN cmte_names        n    ON n."cmte_id" = q."cmte_id"
GROUP BY
    COALESCE(n.cmte_nm, q."cmte_id"),
    q.total_small_amt
ORDER BY
    "committee_name";