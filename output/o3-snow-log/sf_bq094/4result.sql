/* Committees that (a) made at least one contribution to any candidate during
   the 2016 cycle and (b) received individual contributions whose
   individual‐transaction amounts are > 0 and < 200 dollars.  For each
   qualifying committee we return its name, how many different candidates it
   supported, the candidates’ names (alphabetically, comma-separated) and the
   total of those small-dollar individual contributions.                    */

WITH small_dollar_totals AS (      /* 1.  Committees’ ≤$200 individual-gift totals */
    SELECT
        "cmte_id",
        SUM("transaction_amt")        AS small_donor_total
    FROM FEC.FEC."INDIVIDUALS_2016"
    WHERE "transaction_amt" > 0       -- more than $0
      AND "transaction_amt" < 200     -- less than $200
    GROUP BY "cmte_id"
    HAVING SUM("transaction_amt") > 0 -- overall positive
),

candidate_support AS (             /* 2.  Committees that backed ≥1 candidate */
    SELECT DISTINCT
        cc."cmte_id",
        cc."cand_id"
    FROM FEC.FEC."COMMITTEE_CONTRIBUTIONS_2016" cc
    WHERE cc."cand_id" IS NOT NULL
),

committee_names AS (               /* 3.  Get a readable committee name        */
    SELECT DISTINCT
        "cmte_id",
        "cmte_nm"
    FROM FEC.FEC."INDIV16_CM16"
    WHERE "cmte_nm" IS NOT NULL
)

SELECT
    COALESCE(n."cmte_nm", sd."cmte_id")                       AS committee_name,
    COUNT(DISTINCT c."cand_id")                               AS num_unique_candidates_supported,
    LISTAGG(DISTINCT cand."cand_name", ', ')
           WITHIN GROUP (ORDER BY cand."cand_name")           AS candidates_supported_alpha,
    sd.small_donor_total
FROM       small_dollar_totals sd
INNER JOIN candidate_support  c      ON sd."cmte_id" = c."cmte_id"
INNER JOIN FEC.FEC."CANDIDATE_2016" cand
                                     ON cand."cand_id" = c."cand_id"
LEFT  JOIN committee_names     n     ON sd."cmte_id" = n."cmte_id"
GROUP BY
    COALESCE(n."cmte_nm", sd."cmte_id"),
    sd.small_donor_total
ORDER BY
    committee_name;