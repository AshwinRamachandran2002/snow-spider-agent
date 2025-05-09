/*  Top-5 patents filed in the same year as US-9741766-B2
    that are most similar to it on the basis of shared 4-digit CPC codes   */

WITH ref_codes AS (      /* 4-digit CPC codes of the reference patent */
    SELECT DISTINCT
           SUBSTR(cpc_item.value:"code"::STRING, 1, 4)  AS "cpc4"
    FROM   PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS   AS ref,
           LATERAL FLATTEN(input => ref."cpc")          AS cpc_item
    WHERE  ref."publication_number" = 'US-9741766-B2'
),

filing_year AS (         /* filing year of the reference patent */
    SELECT (ref."filing_date" / 10000)::INT            AS "year_val"
    FROM   PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS  AS ref
    WHERE  ref."publication_number" = 'US-9741766-B2'
),

candidate_codes AS (     /* CPC codes of all patents filed in that same year */
    SELECT  pub."publication_number",
            SUBSTR(cpc_item.value:"code"::STRING, 1, 4) AS "cpc4"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS  AS pub,
            LATERAL FLATTEN(input => pub."cpc")         AS cpc_item,
            filing_year  AS fy
    WHERE   (pub."filing_date" / 10000)::INT = fy."year_val"
      AND   pub."publication_number" <> 'US-9741766-B2'
),

overlap_counts AS (      /* count of shared CPC4 codes with the reference patent */
    SELECT  cand."publication_number",
            COUNT(DISTINCT cand."cpc4")  AS "shared_cpc4_cnt"
    FROM    candidate_codes  AS cand
    JOIN    ref_codes        AS ref
           ON cand."cpc4" = ref."cpc4"
    GROUP BY cand."publication_number"
)

SELECT  "publication_number"
FROM    overlap_counts
ORDER BY "shared_cpc4_cnt" DESC NULLS LAST,
         "publication_number"
LIMIT 5;