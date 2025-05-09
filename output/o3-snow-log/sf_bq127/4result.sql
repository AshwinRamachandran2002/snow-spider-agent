/* -------------------------------------------------------------
   Publication families whose very first publication appeared in
   January-2015 together with
       • earliest publication date
       • publication numbers & country codes
       • CPC and IPC codes
       • families that CITE them  (incoming)
       • families they CITE       (out-going)
   All comma-separated and alphabetically sorted
   ------------------------------------------------------------- */

WITH
/* 1. first-publication date per family */
fam_first AS (
    SELECT  "family_id",
            MIN("publication_date") AS first_pub_date
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    GROUP BY "family_id"
),
/* 2. families whose first publication is in January-2015 */
jan15_fams AS (
    SELECT  "family_id",
            first_pub_date
    FROM    fam_first
    WHERE   first_pub_date BETWEEN 20150101 AND 20150131
),
/* 3. publication numbers, country codes, CPC & IPC codes */
family_pubs AS (
    SELECT  p."family_id",
            LISTAGG(DISTINCT p."publication_number", ',')
              WITHIN GROUP (ORDER BY p."publication_number")   AS publication_numbers,
            LISTAGG(DISTINCT p."country_code", ',')
              WITHIN GROUP (ORDER BY p."country_code")         AS country_codes,
            LISTAGG(DISTINCT cpc_f.value:"code"::STRING, ',')
              WITHIN GROUP (ORDER BY cpc_f.value:"code"::STRING) AS cpc_codes,
            LISTAGG(DISTINCT ipc_f.value:"code"::STRING, ',')
              WITHIN GROUP (ORDER BY ipc_f.value:"code"::STRING) AS ipc_codes
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    JOIN    jan15_fams jf ON jf."family_id" = p."family_id"
    LEFT JOIN LATERAL FLATTEN(input => p."cpc") cpc_f
    LEFT JOIN LATERAL FLATTEN(input => p."ipc") ipc_f
    GROUP BY p."family_id"
),
/* 4. families that our Jan-2015 families CITE (out-going) */
cited_fams AS (
    SELECT  jf."family_id",
            LISTAGG(DISTINCT cited_pub."family_id", ',')
              WITHIN GROUP (ORDER BY cited_pub."family_id") AS cited_family_ids
    FROM    jan15_fams jf
    JOIN    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS src_pub
                ON src_pub."family_id" = jf."family_id"
    LEFT JOIN LATERAL FLATTEN(input => src_pub."citation") cit_f
    LEFT JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS cited_pub
                ON cited_pub."publication_number" = cit_f.value:"publication_number"::STRING
    WHERE   cited_pub."family_id" IS NOT NULL
    GROUP BY jf."family_id"
),
/* 5. families that CITE our Jan-2015 families (incoming) */
citing_fams AS (
    SELECT  tgt."family_id"                          AS family_id,
            LISTAGG(DISTINCT src_pub."family_id", ',')
              WITHIN GROUP (ORDER BY src_pub."family_id") AS citing_family_ids
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS src_pub
    LEFT JOIN LATERAL FLATTEN(input => src_pub."citation") cit_f
    LEFT JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS tgt
               ON tgt."publication_number" = cit_f.value:"publication_number"::STRING
    JOIN    jan15_fams jf
               ON jf."family_id" = tgt."family_id"
    GROUP BY tgt."family_id"
)
/* 6. final result */
SELECT  jf."family_id",
        jf.first_pub_date                      AS earliest_publication_date,
        fp.publication_numbers,
        fp.country_codes,
        fp.cpc_codes,
        fp.ipc_codes,
        COALESCE(cf.citing_family_ids, '')     AS citing_family_ids,
        COALESCE(cd.cited_family_ids , '')     AS cited_family_ids
FROM    jan15_fams      jf
LEFT JOIN family_pubs   fp ON fp."family_id" = jf."family_id"
LEFT JOIN citing_fams   cf ON cf.family_id   = jf."family_id"
LEFT JOIN cited_fams    cd ON cd."family_id" = jf."family_id"
ORDER BY jf."family_id";