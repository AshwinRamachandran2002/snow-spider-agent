/* ---------------------------------------------------------------
   Top‑5 U.S. patents (grant date 2010‑2023) having the largest
   total granted‑claim word‑count.  Data for §101 rejections or
   office actions is not available in the exposed catalogue, so
   FIRST_OFFICE_ACTION_DATE is returned as NULL.                 
-----------------------------------------------------------------*/

WITH grants AS (   -- granted U.S. patent publications 2010‑2023
    SELECT
        p."application_number"        AS appl_no,
        p."publication_number"        AS grant_pub_no,
        p."grant_date"                AS grant_dt            -- alias renamed
    FROM PATENTS_USPTO.PATENTS.PUBLICATIONS p
    WHERE p."kind_code" LIKE 'B%'                -- granted documents
      AND p."grant_date" BETWEEN 20100101 AND 20231231
), -----------------------------------------------------------------
first_pub AS (     -- earliest publication for each application
    SELECT
        p."application_number"                                          AS appl_no,
        FIRST_VALUE(p."publication_number")
            OVER (PARTITION BY p."application_number"
                  ORDER BY p."publication_date")                        AS first_pub_no,
        FIRST_VALUE(p."publication_date")
            OVER (PARTITION BY p."application_number"
                  ORDER BY p."publication_date")                        AS first_pub_date
    FROM PATENTS_USPTO.PATENTS.PUBLICATIONS p
), -----------------------------------------------------------------
claim_len AS (     -- total word‑count of all granted claims
    SELECT
        pcs."pat_no"                        AS patent_no,
        SUM(pcs."word_ct"::INT)            AS grant_claim_words
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS.PATENT_CLAIMS_STATS pcs
    GROUP BY pcs."pat_no"
), -----------------------------------------------------------------
mapping AS (       -- application‑digits → granted patent number
    SELECT DISTINCT
        REGEXP_REPLACE(d."appno_doc_num",'[^0-9]','')   AS appl_id_digits,
        d."grant_doc_num"                              AS patent_no
    FROM PATENTS_USPTO.USPTO_OCE_ASSIGNMENT.DOCUMENTID d
    WHERE d."grant_doc_num" IS NOT NULL
), -----------------------------------------------------------------
appl_to_pat AS (   -- collapse mapping to unique app↔patent pair
    SELECT
        m.patent_no,
        MAX(m.appl_id_digits) AS appl_id_digits
    FROM mapping m
    GROUP BY m.patent_no
) -----------------------------------------------------------------
SELECT
    cl.patent_no                       AS "GRANTED_PATENT",
    fp.first_pub_no                    AS "FIRST_PUBLICATION_NO",
    fp.first_pub_date                  AS "FIRST_PUBLICATION_DATE",
    NULL                               AS "FIRST_OFFICE_ACTION_DATE",
    g.grant_dt                         AS "GRANT_DATE",
    cl.grant_claim_words               AS "GRANTED_CLAIM_WORDS"
FROM grants            g
JOIN appl_to_pat       ap  ON ap.appl_id_digits = REGEXP_REPLACE(g.appl_no,'[^0-9]','')
JOIN claim_len         cl  ON cl.patent_no      = ap.patent_no
JOIN first_pub         fp  ON fp.appl_no        = g.appl_no
ORDER BY cl.grant_claim_words DESC NULLS LAST,
         cl.patent_no
LIMIT 5;