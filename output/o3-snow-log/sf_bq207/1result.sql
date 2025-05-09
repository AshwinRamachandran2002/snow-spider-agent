WITH independent_claims AS (                 -- claim-level data + publication metadata
    SELECT
        pc."pub_no",
        pc."appl_id"                             AS "application_id_raw",
        pc."claim_no",
        pc."claim_txt",
        mp."publication_number",
        pb."application_number",
        pb."publication_date"
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS."PGPUB_CLAIMS_FULLTEXT" pc
    JOIN PATENTS_USPTO.USPTO_OCE_CLAIMS."MATCH"                 mp
         ON pc."pub_no" = mp."pub_no"
    JOIN PATENTS_USPTO.PATENTS."PUBLICATIONS"                   pb
         ON mp."publication_number" = pb."publication_number"
    WHERE pc."ind_flg" = '1'                    -- independent claims only
),
claims_with_wc AS (                            -- add word count + earliest pub per app
    SELECT
        ic.*,
        ARRAY_SIZE(
            SPLIT(
                TRIM(REGEXP_REPLACE(ic."claim_txt", '[^A-Za-z0-9]+', ' ')),
                ' '
            )
        )                                       AS "word_count",
        MIN(ic."publication_date") OVER
            (PARTITION BY ic."application_number") AS "earliest_pub_date"
    FROM independent_claims ic
)
SELECT
    "publication_number",
    "application_number",
    "claim_no",
    "word_count"
FROM claims_with_wc
WHERE "publication_date" = "earliest_pub_date"   -- keep only earliest pub per app
ORDER BY "word_count" DESC NULLS LAST
LIMIT 100;