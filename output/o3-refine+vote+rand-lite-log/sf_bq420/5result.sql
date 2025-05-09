WITH grant_pubs AS (   -- U.S. patents granted 2010‑2023
    SELECT  pub."publication_number"               AS granted_publication_number,
            pub."family_id",
            pub."application_number",
            pub."grant_date"                       AS grant_date,
            pub."filing_date"                      AS first_office_action_date,  -- proxy
            SPLIT_PART(pub."publication_number",'-',2) AS pat_no_numeric
    FROM    PATENTS_USPTO.PATENTS.PUBLICATIONS pub
    WHERE   pub."country_code" = 'US'
      AND   pub."kind_code"    LIKE 'B%'           -- granted docs
      AND   pub."grant_date"  BETWEEN 20100101 AND 20231231
), 
grant_claim_lengths AS (  -- attach length of granted claims
    SELECT  gp.*,
            TO_NUMBER(pds."pat_wrd_ct") AS granted_claim_word_count
    FROM    grant_pubs gp
    JOIN    PATENTS_USPTO.USPTO_OCE_CLAIMS.PATENT_DOCUMENT_STATS pds
            ON pds."pat_no" = gp.pat_no_numeric
),
first_pubs AS (           -- earliest U.S. publication in each family
    SELECT  fp."family_id",
            fp."publication_number"  AS first_publication_number,
            fp."publication_date"    AS first_publication_date
    FROM   (
        SELECT  pub."family_id",
                pub."publication_number",
                pub."publication_date",
                ROW_NUMBER() OVER (PARTITION BY pub."family_id"
                                   ORDER BY pub."publication_date") AS rn
        FROM    PATENTS_USPTO.PATENTS.PUBLICATIONS pub
        WHERE   pub."country_code" = 'US'
    ) fp
    WHERE  fp.rn = 1
),
combined AS (
    SELECT  gcl.*,
            fp.first_publication_number,
            fp.first_publication_date
    FROM    grant_claim_lengths gcl
    LEFT JOIN first_pubs fp
           ON fp."family_id" = gcl."family_id"
)
SELECT  first_publication_number,
        first_publication_date,
        granted_publication_number,
        granted_claim_word_count  AS length_of_granted_claims,
        first_office_action_date,     -- first PTO action proxy
        grant_date
FROM    combined
ORDER BY granted_claim_word_count DESC NULLS LAST,
         grant_date
LIMIT 5;