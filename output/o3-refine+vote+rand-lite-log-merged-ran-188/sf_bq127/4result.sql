/*  For every patent family whose very first publication appeared in
    January-2015, gather:
      • earliest publication date
      • all publication numbers (comma-separated, alphabetical)
      • all country codes   (comma-separated, alphabetical)
      • all CPC codes       (comma-separated, alphabetical)
      • all IPC codes       (comma-separated, alphabetical)
      • families this family CITES
      • families that CITE this family
*/
WITH jan15 AS (  ---------------------------------------------------- 1. target families
    SELECT  "family_id",
            MIN("publication_date") AS "earliest_pub_date"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    GROUP BY "family_id"
    HAVING  MIN("publication_date") BETWEEN 20150101 AND 20150131
),

pub_lists AS (  ----------------------------------------------------- 2. pub #s & country codes
    SELECT  p."family_id",
            LISTAGG( DISTINCT p."publication_number", ',' )
              WITHIN GROUP (ORDER BY p."publication_number") AS pub_numbers,
            LISTAGG( DISTINCT p."country_code", ',' )
              WITHIN GROUP (ORDER BY p."country_code")      AS country_codes
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    JOIN    jan15 j USING ("family_id")
    GROUP BY p."family_id"
),

cpc_flat AS (  ------------------------------------------------------- 3. CPC codes
    SELECT DISTINCT
            p."family_id",
            c.value:"code"::STRING AS cpc_code
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    JOIN    jan15 j USING ("family_id"),
            LATERAL FLATTEN(INPUT => p."cpc") c
    WHERE   c.value:"code" IS NOT NULL
),
cpc_lists AS (
    SELECT  "family_id",
            LISTAGG( DISTINCT cpc_code, ',' )
              WITHIN GROUP (ORDER BY cpc_code) AS cpc_codes
    FROM    cpc_flat
    GROUP BY "family_id"
),

ipc_flat AS (  ------------------------------------------------------- 4. IPC codes
    SELECT DISTINCT
            p."family_id",
            i.value:"code"::STRING AS ipc_code
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    JOIN    jan15 j USING ("family_id"),
            LATERAL FLATTEN(INPUT => p."ipc") i
    WHERE   i.value:"code" IS NOT NULL
),
ipc_lists AS (
    SELECT  "family_id",
            LISTAGG( DISTINCT ipc_code, ',' )
              WITHIN GROUP (ORDER BY ipc_code) AS ipc_codes
    FROM    ipc_flat
    GROUP BY "family_id"
),

out_cites AS (  ------------------------------------------------------ 5. families this family cites
    SELECT DISTINCT
            p1."family_id"                     AS src_family,
            p2."family_id"                     AS tgt_family
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p1
    JOIN    jan15 j           ON j."family_id" = p1."family_id",
            LATERAL FLATTEN(INPUT => p1."citation") c
    JOIN    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p2
           ON c.value:"publication_number"::STRING = p2."publication_number"
    WHERE   c.value:"publication_number" IS NOT NULL
),
out_lists AS (
    SELECT  src_family  AS "family_id",
            LISTAGG( DISTINCT tgt_family, ',' )
              WITHIN GROUP (ORDER BY tgt_family) AS cited_family_ids
    FROM    out_cites
    GROUP BY src_family
),

in_cites AS (   ------------------------------------------------------ 6. families that cite this family
    SELECT DISTINCT
            p_other."family_id"                AS citing_family,
            p_jan."family_id"                  AS cited_family
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p_other,
            LATERAL FLATTEN(INPUT => p_other."citation") c
    JOIN    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p_jan
           ON c.value:"publication_number"::STRING = p_jan."publication_number"
    JOIN    jan15 j ON j."family_id" = p_jan."family_id"
    WHERE   c.value:"publication_number" IS NOT NULL
),
in_lists AS (
    SELECT  cited_family  AS "family_id",
            LISTAGG( DISTINCT citing_family, ',' )
              WITHIN GROUP (ORDER BY citing_family) AS citing_family_ids
    FROM    in_cites
    GROUP BY cited_family
)

SELECT  j."family_id",
        j."earliest_pub_date",
        pub_lists.pub_numbers,
        pub_lists.country_codes,
        cpc_lists.cpc_codes,
        ipc_lists.ipc_codes,
        out_lists.cited_family_ids,
        in_lists.citing_family_ids
FROM    jan15 j
LEFT JOIN pub_lists  USING ("family_id")
LEFT JOIN cpc_lists  USING ("family_id")
LEFT JOIN ipc_lists  USING ("family_id")
LEFT JOIN out_lists  USING ("family_id")
LEFT JOIN in_lists   USING ("family_id")
ORDER BY j."earliest_pub_date", j."family_id";