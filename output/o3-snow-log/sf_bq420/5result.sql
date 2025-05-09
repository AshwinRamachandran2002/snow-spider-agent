/*  Top-5 longest-claim U.S. patents (granted 2010-2023) that have at least one
    PTAB document whose title contains “office action”.
    Returned:
      • first U.S. publication number & date
      • word-count of the filed (published) claims
      • word-count of the granted claims
      • grant date
      • earliest PTAB “office action” filing date                                   */

WITH office_actions AS (        /* earliest “office action” per patent            */
    SELECT   oa.pat_no,
             MIN(TO_DATE(doc.value:"FilingDatetime"::STRING))
                     AS first_office_action_date
    FROM  (
            SELECT  TRY_TO_NUMBER(t."PatentNumber") AS pat_no,
                    t."Documents"                   AS docs
            FROM    PATENTS_USPTO.USPTO_PTAB."TRIALS_201710" t
          ) oa,
          LATERAL FLATTEN (INPUT => oa.docs) doc
    WHERE  oa.pat_no IS NOT NULL
      AND  LOWER(doc.value:"Title"::STRING) LIKE '%office action%'
    GROUP BY oa.pat_no
),

grant_info AS (                /* granted U.S. patents (2010-2023)                */
    SELECT  m."pat_no"::INTEGER                 AS pat_no,
            p."grant_date"                      AS grant_dt,
            p."family_id"
    FROM    PATENTS_USPTO.USPTO_OCE_CLAIMS."MATCH"      m
    JOIN    PATENTS_USPTO.PATENTS."PUBLICATIONS"        p
           ON p."publication_number" = m."publication_number"
    WHERE   p."kind_code" LIKE 'B%'                -- granted patents
      AND   p."grant_date" BETWEEN 20100101 AND 20231231
),

granted_claim_len AS (         /* word-count of granted claims                    */
    SELECT  TRY_TO_NUMBER("pat_no")              AS pat_no,
            TRY_TO_NUMBER("pat_wrd_ct")          AS granted_claim_words
    FROM    PATENTS_USPTO.USPTO_OCE_CLAIMS."PATENT_DOCUMENT_STATS"
    WHERE   TRY_TO_NUMBER("pat_no")  IS NOT NULL
      AND   TRY_TO_NUMBER("pat_wrd_ct") IS NOT NULL
),

first_pub AS (                 /* earliest U.S. publication per patent            */
    SELECT  gi.pat_no,
            pub."publication_number"             AS first_pub_no,
            pub."publication_date"               AS first_pub_date,
            ROW_NUMBER() OVER (PARTITION BY gi.pat_no
                               ORDER BY pub."publication_date") AS rn
    FROM    grant_info gi
    JOIN    PATENTS_USPTO.PATENTS."PUBLICATIONS" pub
          ON pub."family_id"   = gi."family_id"
         AND pub."country_code" = 'US'
),

filed_claim_len AS (           /* word-count of claims in that publication        */
    SELECT  fp.pat_no,
            TRY_TO_NUMBER(pds."pub_wrd_ct")      AS filed_claim_words
    FROM    first_pub fp
    JOIN    PATENTS_USPTO.USPTO_OCE_CLAIMS."MATCH"              m
          ON m."publication_number" = fp.first_pub_no
    JOIN    PATENTS_USPTO.USPTO_OCE_CLAIMS."PGPUB_DOCUMENT_STATS" pds
          ON pds."pub_no" = m."pub_no"
    WHERE   fp.rn = 1
      AND   TRY_TO_NUMBER(pds."pub_wrd_ct") IS NOT NULL
)

/* ---------------- final selection ------------------------------------------- */
SELECT  gi.pat_no                              AS us_patent_no,
        fp.first_pub_no                        AS first_publication_number,
        fp.first_pub_date                      AS first_publication_date,
        fcl.filed_claim_words,
        gcl.granted_claim_words,
        gi.grant_dt                            AS grant_date,
        oa.first_office_action_date
FROM       grant_info         gi
JOIN       granted_claim_len  gcl ON gcl.pat_no = gi.pat_no
JOIN       first_pub          fp  ON fp.pat_no  = gi.pat_no AND fp.rn = 1
LEFT JOIN  filed_claim_len    fcl ON fcl.pat_no = gi.pat_no
LEFT JOIN  office_actions     oa  ON oa.pat_no  = gi.pat_no
ORDER BY   gcl.granted_claim_words DESC NULLS LAST
LIMIT 5;