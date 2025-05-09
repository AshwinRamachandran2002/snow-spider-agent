/*   Families whose first publication was issued in January‑2015,
     with their publications, CPC / IPC codes, and the families
     they cite and that cite them.                                       */

WITH target_families AS (      -- 1) families whose earliest publication is in Jan‑2015
    SELECT
        "family_id",
        MIN("publication_date") AS earliest_pub_date
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    GROUP BY "family_id"
    HAVING earliest_pub_date BETWEEN 20150101 AND 20150131
),

family_pubs AS (               -- 2) all publications belonging to those families
    SELECT
        p."family_id",
        p."publication_number",
        p."country_code",
        p."cpc",
        p."ipc"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    JOIN target_families tf
      ON p."family_id" = tf."family_id"
),

/* ------------- CPC & IPC codes ---------------- */
cpc_codes AS (
    SELECT DISTINCT
        fp."family_id",
        c.value:"code"::TEXT AS code
    FROM family_pubs fp,
         LATERAL FLATTEN(input => fp."cpc") c
    WHERE c.value:"code" IS NOT NULL
),
ipc_codes AS (
    SELECT DISTINCT
        fp."family_id",
        i.value:"code"::TEXT AS code
    FROM family_pubs fp,
         LATERAL FLATTEN(input => fp."ipc") i
    WHERE i.value:"code" IS NOT NULL
),

/* ------------- families that the target families CITE --------------- */
out_cited AS (
    SELECT DISTINCT
        tf."family_id"              AS source_family,
        p2."family_id"              AS cited_family
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p1
    JOIN target_families tf
      ON p1."family_id" = tf."family_id",
         LATERAL FLATTEN(input => p1."citation") c
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p2
      ON p2."publication_number" = c.value:"publication_number"::TEXT
    WHERE c.value:"publication_number" IS NOT NULL
),

/* ------------- families that CITE the target families --------------- */
/* use ABS_AND_EMB.cited_by so that we only flatten the small set of    */
/* target‑family publications, avoiding a full scan of all publications */
inc_citing AS (
    SELECT DISTINCT
        p_citing."family_id"        AS citing_family,
        fp."family_id"              AS target_family
    FROM family_pubs fp
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB ae
      ON ae."publication_number" = fp."publication_number"
    ,  LATERAL FLATTEN(input => ae."cited_by") cb
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p_citing
      ON p_citing."publication_number" = cb.value:"publication_number"::TEXT
    WHERE cb.value:"publication_number" IS NOT NULL
),

/* ------------- helper aggregated lists ------------------------------ */
pub_list AS (
    SELECT
        "family_id",
        LISTAGG(DISTINCT "publication_number", ',')
          WITHIN GROUP (ORDER BY "publication_number")           AS publication_numbers,
        LISTAGG(DISTINCT "country_code", ',')
          WITHIN GROUP (ORDER BY "country_code")                 AS country_codes
    FROM family_pubs
    GROUP BY "family_id"
),
cpc_list AS (
    SELECT
        "family_id",
        LISTAGG(DISTINCT code, ',')
          WITHIN GROUP (ORDER BY code)                           AS cpc_codes
    FROM cpc_codes
    GROUP BY "family_id"
),
ipc_list AS (
    SELECT
        "family_id",
        LISTAGG(DISTINCT code, ',')
          WITHIN GROUP (ORDER BY code)                           AS ipc_codes
    FROM ipc_codes
    GROUP BY "family_id"
),
out_list AS (
    SELECT
        source_family AS "family_id",
        LISTAGG(DISTINCT cited_family, ',')
          WITHIN GROUP (ORDER BY cited_family)                   AS families_cited
    FROM out_cited
    GROUP BY source_family
),
inc_list AS (
    SELECT
        target_family AS "family_id",
        LISTAGG(DISTINCT citing_family, ',')
          WITHIN GROUP (ORDER BY citing_family)                  AS families_citing_this
    FROM inc_citing
    GROUP BY target_family
)

/* -------------------------- final result ---------------------------- */
SELECT
    tf."family_id",
    tf.earliest_pub_date                             AS earliest_publication_date,
    pl.publication_numbers,
    pl.country_codes,
    cl.cpc_codes,
    il.ipc_codes,
    ol.families_cited,
    icl.families_citing_this
FROM target_families tf
LEFT JOIN pub_list  pl  ON pl."family_id"  = tf."family_id"
LEFT JOIN cpc_list  cl  ON cl."family_id"  = tf."family_id"
LEFT JOIN ipc_list  il  ON il."family_id"  = tf."family_id"
LEFT JOIN out_list  ol  ON ol."family_id"  = tf."family_id"
LEFT JOIN inc_list  icl ON icl."family_id" = tf."family_id"
ORDER BY tf.earliest_pub_date, tf."family_id";