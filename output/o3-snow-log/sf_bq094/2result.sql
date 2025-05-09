/*----------------------------------------------------------
 Committees (2016 cycle) that
   • supported at least one candidate (cand_id not null)
   • received ONLY small-dollar individual contributions 
     (each > 0 and < 200) whose TOTAL is > 0 and < 200
   • return committee name, # of unique candidates,
     candidates’ names (alphabetical, comma-separated),
     and the summed small-dollar total
----------------------------------------------------------*/
WITH small_donations AS (
    SELECT
        i."cmte_id",
        i."cmte_nm",
        i."cand_id",
        i."transaction_amt"
    FROM FEC.FEC.INDIV16_CM16 i
    WHERE i."transaction_amt" > 0
      AND i."transaction_amt" < 200             -- small-dollar only
),
committee_totals AS (
    SELECT
        sd."cmte_id",
        MIN(sd."cmte_nm")                                    AS committee_name,
        COUNT(DISTINCT sd."cand_id")                         AS num_candidates,
        LISTAGG(DISTINCT c."cand_name", ', ')
            WITHIN GROUP (ORDER BY c."cand_name")            AS candidate_names,
        SUM(sd."transaction_amt")                            AS small_dollar_total
    FROM small_donations sd
    LEFT JOIN FEC.FEC.CANDIDATE_2016 c
           ON sd."cand_id" = c."cand_id"
    GROUP BY sd."cmte_id"
    HAVING SUM(sd."transaction_amt") > 0        -- overall > 0
       AND SUM(sd."transaction_amt") < 200      -- and < 200
       AND COUNT(DISTINCT sd."cand_id") > 0     -- supported ≥1 candidate
)
SELECT
    committee_name      AS "COMMITTEE_NAME",
    num_candidates      AS "UNIQUE_CANDIDATES_SUPPORTED",
    candidate_names     AS "CANDIDATE_NAMES",
    small_dollar_total  AS "TOTAL_SMALL_DOLLAR_CONTRIBUTIONS"
FROM committee_totals
ORDER BY committee_name;