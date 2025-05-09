WITH first_publication AS (   -- earliest publication per application
    SELECT
        "application_number_formatted",
        MIN("publication_date") AS earliest_publication_date
    FROM "PATENTS_USPTO"."PATENTS"."PUBLICATIONS"
    GROUP BY "application_number_formatted"
),
independent_claims AS (       -- independent claims with a numeric word count
    SELECT
        "pat_no",
        "appl_id",
        "claim_no",
        TRY_TO_NUMBER("word_ct") AS word_count
    FROM "PATENTS_USPTO"."USPTO_OCE_CLAIMS"."PATENT_CLAIMS_STATS"
    WHERE "ind_flg" = '1'
      AND TRY_TO_NUMBER("word_ct") IS NOT NULL
),
joined AS (                   -- link claims → patent → earliest publication
    SELECT
        pub."publication_number"        AS publication_number,
        ic."appl_id"                    AS application_number,
        ic."claim_no"                   AS claim_num,
        ic.word_count                   AS word_count
    FROM independent_claims ic
    JOIN "PATENTS_USPTO"."USPTO_OCE_CLAIMS"."MATCH"        m
          ON m."pat_no" = ic."pat_no"
    JOIN "PATENTS_USPTO"."PATENTS"."PUBLICATIONS"          pub
          ON pub."publication_number" = m."publication_number"
    JOIN first_publication fp
          ON fp."application_number_formatted" = pub."application_number_formatted"
         AND fp.earliest_publication_date      = pub."publication_date"
)
SELECT
    publication_number,
    application_number,
    claim_num,
    word_count
FROM joined
ORDER BY word_count DESC NULLS LAST, publication_number
LIMIT 100;