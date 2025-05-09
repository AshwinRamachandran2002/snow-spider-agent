WITH independent AS (  -- all independent claims with their word counts
    SELECT
        "pat_no",
        "claim_no",
        TO_NUMBER("word_ct") AS word_ct
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS.PATENT_CLAIMS_STATS
    WHERE "ind_flg" = '1'
),

matched_pub AS (       -- link patents to DOCDB-style publication numbers
    SELECT
        "pat_no",
        "publication_number"
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS.MATCH
),

pubs AS (              -- bring in application numbers & publication dates
    SELECT
        "publication_number",
        "application_number",
        TO_NUMBER("publication_date") AS pub_dt
    FROM PATENTS_USPTO.PATENTS.PUBLICATIONS
),

earliest AS (          -- keep only the first (earliest) publication per application
    SELECT
        "application_number",
        "publication_number" AS earliest_pub_no
    FROM (
        SELECT
            "application_number",
            "publication_number",
            pub_dt,
            ROW_NUMBER() OVER (PARTITION BY "application_number"
                               ORDER BY pub_dt) AS rn
        FROM pubs
    )
    WHERE rn = 1
)

SELECT
    e.earliest_pub_no       AS "earliest_publication_number",
    p."application_number"  AS "application_number",
    i."claim_no"            AS "claim_number",
    i.word_ct               AS "word_count"
FROM independent  i
JOIN matched_pub  mp ON i."pat_no"            = mp."pat_no"
JOIN pubs         p  ON mp."publication_number" = p."publication_number"
JOIN earliest     e  ON p."application_number"  = e."application_number"
ORDER BY i.word_ct DESC NULLS LAST
LIMIT 100;