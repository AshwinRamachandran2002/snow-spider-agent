WITH independent_claims AS (
    SELECT
        TRY_TO_NUMBER("word_ct")            AS "word_count",
        "pat_no",
        "claim_no"
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS.PATENT_CLAIMS_STATS
    WHERE "ind_flg" = '1'
),
claim_to_publication AS (
    SELECT
        ic."word_count",
        ic."claim_no",
        ic."pat_no",
        m."publication_number"
    FROM independent_claims ic
    INNER JOIN PATENTS_USPTO.USPTO_OCE_CLAIMS.MATCH m
            ON ic."pat_no" = m."pat_no"
),
publication_app_dates AS (
    SELECT
        cp."word_count",
        cp."claim_no",
        cp."publication_number",
        pub."application_number",
        pub."publication_date",
        ROW_NUMBER() OVER (
            PARTITION BY pub."application_number"
            ORDER BY pub."publication_date" ASC
        ) AS rn_earliest_pub
    FROM claim_to_publication cp
    INNER JOIN PATENTS_USPTO.PATENTS.PUBLICATIONS pub
            ON cp."publication_number" = pub."publication_number"
)
SELECT
    "publication_number",
    "application_number",
    "claim_no",
    "word_count"
FROM publication_app_dates
WHERE rn_earliest_pub = 1
ORDER BY "word_count" DESC NULLS LAST, "publication_number"
LIMIT 100;