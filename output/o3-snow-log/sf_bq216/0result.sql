WITH ref AS (
    /* CPC 4-digit codes and filing year of the reference patent */
    SELECT 
        ARRAY_AGG(DISTINCT SUBSTR(cpc_f.value:"code"::STRING, 0, 4))           AS "ref_cpc4",
        FLOOR(p."filing_date" / 10000)                                         AS "ref_year"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS            p,
         LATERAL FLATTEN(input => p."cpc")                     cpc_f
    WHERE p."publication_number" = 'US-9741766-B2'
    GROUP BY FLOOR(p."filing_date" / 10000)
), candidates AS (
    /* All patents filed in the same year as the reference patent,
       together with their CPC 4-digit code sets                           */
    SELECT
        p."publication_number",
        ARRAY_AGG(DISTINCT SUBSTR(cpc_f.value:"code"::STRING, 0, 4)) AS "cand_cpc4"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    JOIN ref r
         ON FLOOR(p."filing_date" / 10000) = r."ref_year"
    ,    LATERAL FLATTEN(input => p."cpc") cpc_f
    GROUP BY p."publication_number"
), scored AS (
    /* Overlap score = number of shared CPC 4-digit codes                  */
    SELECT
        c."publication_number",
        ARRAY_SIZE(ARRAY_INTERSECTION(c."cand_cpc4", r."ref_cpc4")) AS "overlap_cnt"
    FROM candidates c
    CROSS JOIN ref r
    WHERE c."publication_number" <> 'US-9741766-B2'
)
SELECT "publication_number"
FROM   scored
WHERE  "overlap_cnt" > 0                      -- keep only technologically related patents
ORDER BY "overlap_cnt" DESC NULLS LAST,
         "publication_number"
LIMIT 5;