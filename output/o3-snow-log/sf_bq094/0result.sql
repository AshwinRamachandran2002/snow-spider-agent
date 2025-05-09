/*==============================================================
  Committees (2016) that
    • made at least one contribution to a candidate
    • received individual “small-dollar” contributions
      > 0 and < 200 dollars whose TOTAL > 0
  Output
    – committee name  (falls back to committee_id if no name)
    – # unique candidates supported
    – candidates’ names (alphabetical, comma-separated)
    – total small-dollar amount
==============================================================*/
WITH small_dollar AS (          -- 1.  individual gifts 0–200 $
    SELECT
        "cmte_id",
        SUM("transaction_amt")   AS total_small
    FROM FEC.FEC.INDIVIDUALS_2016
    WHERE "transaction_amt" > 0
      AND "transaction_amt" < 200
    GROUP BY "cmte_id"
    HAVING SUM("transaction_amt") > 0                      -- must be >0 overall
),
supported_candidates AS (       -- 2. committees that backed ≥1 candidate
    SELECT DISTINCT
        "cmte_id",
        "cand_id"
    FROM FEC.FEC.COMMITTEE_CONTRIBUTIONS_2016
    WHERE "cand_id" IS NOT NULL
),
committee_candidates AS (       -- 3. keep only committees that also have small-$
    SELECT
        sc."cmte_id",
        sc."cand_id",
        c."cand_name"
    FROM supported_candidates sc
    JOIN small_dollar      sd ON sd."cmte_id" = sc."cmte_id"
    JOIN FEC.FEC.CANDIDATE_2016 c
         ON c."cand_id" = sc."cand_id"
),
agg AS (                         -- 4. aggregate candidate info
    SELECT
        "cmte_id",
        COUNT(DISTINCT "cand_id")                                              AS num_cands,
        LISTAGG( DISTINCT "cand_name", ', ' ) 
            WITHIN GROUP (ORDER BY "cand_name")                                AS cand_names
    FROM committee_candidates
    GROUP BY "cmte_id"
),
cmte_names AS (                  -- 5. fetch committee names where available
    SELECT DISTINCT
        "cmte_id",
        "cmte_nm"
    FROM FEC.FEC.INDIV16_CM16
    WHERE "cmte_nm" IS NOT NULL
)
SELECT
    COALESCE(cn."cmte_nm", a."cmte_id")                 AS "committee_name",
    a.num_cands                                         AS "num_unique_candidates",
    a.cand_names                                        AS "candidate_names",
    sd.total_small                                      AS "total_small_donations"
FROM agg a
JOIN small_dollar  sd ON sd."cmte_id" = a."cmte_id"
LEFT JOIN cmte_names cn ON cn."cmte_id" = a."cmte_id"
ORDER BY "committee_name";