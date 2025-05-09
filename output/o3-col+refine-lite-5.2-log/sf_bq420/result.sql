/* ------------------------------------------------------------------
   TOP‑5 U.S. patents granted 2010‑2023 ranked by total words in the
   granted claims set.  For each patent we also show
      • first (A‑kind) publication number & date
      • proxy “first‑office‑action date”  → earliest filing_date we have
      • word‑count of the claims in that first publication
      • word‑count of the claims in the granted patent
------------------------------------------------------------------- */

WITH first_event AS (               /* proxy for first office action  */
    SELECT
        "application_number",
        MIN("filing_date") AS "first_office_action_date"
    FROM PATENTS_USPTO.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'US'
    GROUP BY "application_number"
),

grants AS (                         /* U.S. grants (kind‑code ‘B’)     */
    SELECT
        p."application_number",
        p."publication_number"          AS "grant_pub_no",
        p."grant_date",
        TRY_TO_NUMBER(
            REGEXP_SUBSTR(p."publication_number", '[0-9]+')
        )                               AS "pat_no_digits"
    FROM PATENTS_USPTO.PATENTS.PUBLICATIONS p
    WHERE p."country_code" = 'US'
      AND p."kind_code"   LIKE 'B%'            -- granted patent
      AND p."grant_date" BETWEEN 20100101 AND 20231231
),

first_app_pub AS (                  /* earliest A‑kind publication     */
    SELECT
        p."application_number",
        MIN(p."publication_date")                            AS "first_pub_date",
        MIN_BY(p."publication_number", p."publication_date") AS "first_pub_no"
    FROM PATENTS_USPTO.PATENTS.PUBLICATIONS p
    WHERE p."country_code" = 'US'
      AND p."kind_code"   LIKE 'A%'            -- application pubs
    GROUP BY p."application_number"
),

grant_claim_stats AS (              /* word‑count of granted claims    */
    SELECT
        TRY_TO_NUMBER(s."pat_no")      AS "pat_no_digits",
        TRY_TO_NUMBER(s."pat_wrd_ct")  AS "grant_claim_word_ct"
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS.PATENT_DOCUMENT_STATS s
),

filed_claim_stats AS (              /* word‑count in first publication */
    SELECT
        ps."pub_no",
        TRY_TO_NUMBER(ps."pub_wrd_ct") AS "filed_claim_word_ct"
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS.PGPUB_DOCUMENT_STATS ps
)

SELECT
    g."grant_pub_no"              AS "patent_publication_number",
    g."grant_date",
    f."first_pub_no"              AS "first_publication_number",
    f."first_pub_date"            AS "first_publication_date",
    fe."first_office_action_date",
    fc."filed_claim_word_ct",
    gc."grant_claim_word_ct"
FROM grants                g
JOIN first_event           fe  ON fe."application_number" = g."application_number"
JOIN first_app_pub         f   ON f."application_number"  = g."application_number"
LEFT JOIN grant_claim_stats gc ON gc."pat_no_digits"      = g."pat_no_digits"
LEFT JOIN filed_claim_stats fc ON fc."pub_no"             = REGEXP_SUBSTR(f."first_pub_no", '[0-9]+')
ORDER BY gc."grant_claim_word_ct" DESC NULLS LAST
LIMIT 5;