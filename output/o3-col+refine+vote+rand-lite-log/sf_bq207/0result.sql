WITH earliest_pub_per_app AS (          -- earliest publication for each application
    SELECT
        "application_number",
        MIN("publication_date") AS "earliest_pub_date"
    FROM PATENTS_USPTO.PATENTS.PUBLICATIONS
    GROUP BY "application_number"
),
independent_claims AS (                 -- independent-claim word counts
    SELECT
        "pat_no",
        "claim_no",
        CAST("word_ct" AS NUMBER) AS "word_ct"
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS.PATENT_CLAIMS_STATS
    WHERE "ind_flg" = '1'
)

SELECT
    pub."publication_number"  AS "earliest_publication_number",
    pub."application_number"  AS "application_number",
    ic."claim_no"             AS "independent_claim_no",
    ic."word_ct"              AS "word_count"
FROM independent_claims                       ic
JOIN PATENTS_USPTO.USPTO_OCE_CLAIMS.MATCH      m
      ON ic."pat_no" = m."pat_no"
JOIN PATENTS_USPTO.PATENTS.PUBLICATIONS        pub
      ON m."publication_number" = pub."publication_number"
JOIN earliest_pub_per_app                      ep
      ON  pub."application_number" = ep."application_number"
      AND pub."publication_date"   = ep."earliest_pub_date"
ORDER BY ic."word_ct" DESC NULLS LAST
LIMIT 100;