WITH pub_min AS (   /* earliest publication per family */
    SELECT  "family_id",
            MIN("publication_date") AS earliest_pub_date
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    GROUP BY "family_id"
),
target_fam AS (     /* families whose very first publication is in Jan-2015 */
    SELECT  "family_id",
            earliest_pub_date
    FROM    pub_min
    WHERE   earliest_pub_date BETWEEN 20150101 AND 20150131
),
/* ---------------------------------------------------------------------- */
/* all publications that belong to the target families                    */
family_pubs AS (
    SELECT  p."family_id",
            p."publication_number",
            p."country_code"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
            JOIN target_fam tf
              ON p."family_id" = tf."family_id"
),
/* distinct CPC codes for every target family */
family_cpc AS (
    SELECT  DISTINCT
            p."family_id",
            f.value:"code"::string AS cpc_code
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
            JOIN target_fam tf
              ON p."family_id" = tf."family_id",
            LATERAL FLATTEN (INPUT => p."cpc") f
    WHERE   f.value:"code" IS NOT NULL
),
/* distinct IPC codes for every target family */
family_ipc AS (
    SELECT  DISTINCT
            p."family_id",
            f.value:"code"::string AS ipc_code
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
            JOIN target_fam tf
              ON p."family_id" = tf."family_id",
            LATERAL FLATTEN (INPUT => p."ipc") f
    WHERE   f.value:"code" IS NOT NULL
),
/* ---------------------  citation (OUTGOING) --------------------------- */
cited_pubs AS (     /* publication numbers cited by any pub in tgt family */
    SELECT  DISTINCT
            p."family_id"                         AS src_family_id,
            cit.value:"publication_number"::string AS cited_pub_num
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
            JOIN target_fam tf
              ON p."family_id" = tf."family_id",
            LATERAL FLATTEN (INPUT => p."citation") cit
    WHERE   cit.value:"publication_number" IS NOT NULL
),
cited_families AS ( /* map those pub-numbers to their families */
    SELECT  cp.src_family_id,
            q."family_id" AS cited_family_id
    FROM    cited_pubs cp
            JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS q
              ON q."publication_number" = cp.cited_pub_num
),
/* ---------------------  citation (INCOMING) --------------------------- */
target_pub_nums AS (   /* all pub-numbers that belong to tgt families */
    SELECT DISTINCT "publication_number"
    FROM   family_pubs
),
citing_pubs AS (       /* any publication (in any family) that cites them */
    SELECT DISTINCT
           p."family_id"                                           AS citing_family_id,
           tgt."publication_number"                               AS cited_target_pub
    FROM   PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p,
           LATERAL FLATTEN (INPUT => p."citation") cit
           JOIN target_pub_nums tgt
             ON cit.value:"publication_number"::string = tgt."publication_number"
),
citing_families AS (   /* reduce to citing-family  ↔ target-family pairs */
    SELECT  DISTINCT
            fp."family_id"   AS target_family_id,
            cp.citing_family_id
    FROM    citing_pubs cp
            JOIN family_pubs fp
              ON fp."publication_number" = cp.cited_target_pub
)
/* ---------------------------------------------------------------------- */
SELECT  tf."family_id"                               AS FAMILY_ID,
        tf.earliest_pub_date                         AS EARLIEST_PUBLICATION_DATE,
        LISTAGG(DISTINCT fp."publication_number", ', ')
            WITHIN GROUP (ORDER BY fp."publication_number")       AS PUBLICATION_NUMBERS,
        LISTAGG(DISTINCT fp."country_code", ', ')
            WITHIN GROUP (ORDER BY fp."country_code")             AS COUNTRY_CODES,
        LISTAGG(DISTINCT fc.cpc_code, ', ')
            WITHIN GROUP (ORDER BY fc.cpc_code)                   AS CPC_CODES,
        LISTAGG(DISTINCT fi.ipc_code, ', ')
            WITHIN GROUP (ORDER BY fi.ipc_code)                   AS IPC_CODES,
        LISTAGG(DISTINCT cf.cited_family_id, ', ')
            WITHIN GROUP (ORDER BY cf.cited_family_id)            AS CITED_FAMILY_IDS,
        LISTAGG(DISTINCT ct.citing_family_id, ', ')
            WITHIN GROUP (ORDER BY ct.citing_family_id)           AS CITING_FAMILY_IDS
FROM    target_fam tf
        LEFT JOIN family_pubs     fp ON tf."family_id" = fp."family_id"
        LEFT JOIN family_cpc      fc ON tf."family_id" = fc."family_id"
        LEFT JOIN family_ipc      fi ON tf."family_id" = fi."family_id"
        LEFT JOIN cited_families  cf ON tf."family_id" = cf.src_family_id
        LEFT JOIN citing_families ct ON tf."family_id" = ct.target_family_id
GROUP BY tf."family_id", tf.earliest_pub_date
ORDER BY tf."family_id";