/*  Top-5 U.S. patents (granted 2010-2023) having the longest granted-claim
    word-counts, with their first publication info and filed-claim length   */
WITH -------------------------------------------------------------------------
/* 1) Map every granted patent to its very first U.S. publication            */
first_pub AS (
    SELECT
        m."pat_no",
        p."publication_number",
        p."publication_date",
        ROW_NUMBER() OVER (PARTITION BY m."pat_no"
                           ORDER BY p."publication_date") AS rn
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS."MATCH"   m
    JOIN PATENTS_USPTO.PATENTS."PUBLICATIONS"     p
          ON p."publication_number" = m."publication_number"
    WHERE p."country_code" = 'US'
),
first_pub_selected AS (
    SELECT
        "pat_no",
        "publication_number"  AS first_publication_number,
        "publication_date"    AS first_publication_date,
        REGEXP_REPLACE("publication_number",'[^0-9]','') AS pub_no_digits
    FROM first_pub
    WHERE rn = 1
),
/* 2) Granted-claim word counts                                              */
granted_stats AS (
    SELECT
        "pat_no",
        TO_NUMBER("pat_wrd_ct") AS granted_claim_word_count
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS."PATENT_DOCUMENT_STATS"
),
/* 3) Filed (PG-pub) claim word counts                                       */
filed_stats AS (
    SELECT
        "pub_no"                        AS pub_no_digits,
        TO_NUMBER("pub_wrd_ct")         AS filed_claim_word_count
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS."PGPUB_DOCUMENT_STATS"
),
/* 4) Assemble & filter by grant window                                      */
patent_info AS (
    SELECT
        fp."pat_no",
        fp.first_publication_number,
        fp.first_publication_date,
        gs.granted_claim_word_count,
        fs.filed_claim_word_count,
        pg."grant_date"      AS GRANT_DATE      -- upper-case name for later use
    FROM  first_pub_selected                    fp
    JOIN  granted_stats                         gs  ON gs."pat_no" = fp."pat_no"
    LEFT JOIN filed_stats                       fs  ON fs.pub_no_digits = fp.pub_no_digits
    JOIN PATENTS_USPTO.PATENTS."PUBLICATIONS"   pg
         ON pg."publication_number" = fp.first_publication_number
    WHERE pg."grant_date" BETWEEN 20100101 AND 20231231
)
SELECT
    "pat_no"                      AS patent_number,
    first_publication_number,
    first_publication_date,
    filed_claim_word_count        AS filed_claim_words,
    granted_claim_word_count      AS granted_claim_words,
    GRANT_DATE                    AS grant_date
FROM patent_info
ORDER BY granted_claim_word_count DESC NULLS LAST
LIMIT 5;