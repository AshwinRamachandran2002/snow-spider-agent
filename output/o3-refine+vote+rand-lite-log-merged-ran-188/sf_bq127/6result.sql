/*  For every patent family whose VERY FIRST publication date falls in
    January-2015 (20150101-20150131):

    • earliest_pub_date                 – the minimum publication_date
    • publication_numbers               – distinct publication numbers (CSV, alpha-sorted)
    • country_codes                     – distinct country codes   (CSV, alpha-sorted)
    • cpc_codes                         – distinct CPC codes       (CSV, alpha-sorted)
    • ipc_codes                         – distinct IPC codes       (CSV, alpha-sorted)
    • cites_family_ids   (outgoing)     – distinct family IDs this family CITES
    • cited_by_family_ids (incoming)    – distinct family IDs that CITE this family
*/

WITH jan15 AS (    -------------------------------------------------- 1) families first seen in Jan-2015
    SELECT  "family_id",
            MIN("publication_date")           AS "earliest_pub_date"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE."PUBLICATIONS"
    GROUP BY "family_id"
    HAVING  MIN("publication_date") BETWEEN 20150101 AND 20150131
),

pub_info AS (      -------------------------------------------------- 2) pubs & countries
    SELECT  p."family_id",
            p."publication_number",
            p."country_code"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE."PUBLICATIONS"  p
    JOIN    jan15 j
           ON p."family_id" = j."family_id"
),

cpc_codes AS (     -------------------------------------------------- 3) CPC codes
    SELECT  p."family_id",
            c.value:"code"::STRING            AS "cpc_code"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE."PUBLICATIONS"  p
    JOIN    jan15 j
           ON p."family_id" = j."family_id",
            LATERAL FLATTEN(INPUT => p."cpc") c
    WHERE   c.value:"code" IS NOT NULL
),

ipc_codes AS (     -------------------------------------------------- 4) IPC codes
    SELECT  p."family_id",
            i.value:"code"::STRING            AS "ipc_code"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE."PUBLICATIONS"  p
    JOIN    jan15 j
           ON p."family_id" = j."family_id",
            LATERAL FLATTEN(INPUT => p."ipc") i
    WHERE   i.value:"code" IS NOT NULL
),

outgoing AS (      -------------------------------------------------- 5) family → cited families
    SELECT  DISTINCT
            p."family_id"                     AS source_family,
            tgt."family_id"                   AS cited_family
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE."PUBLICATIONS"  p
    JOIN    jan15 j
           ON p."family_id" = j."family_id",
            LATERAL FLATTEN(INPUT => p."citation") cit
    JOIN    PATENTS_GOOGLE.PATENTS_GOOGLE."PUBLICATIONS"  tgt
           ON tgt."publication_number" = cit.value:"publication_number"::STRING
    WHERE   cit.value:"publication_number" IS NOT NULL
),

incoming AS (      -------------------------------------------------- 6) families that cite a Jan-2015 family
    SELECT  DISTINCT
            tgt."family_id"                   AS target_family,
            src."family_id"                   AS citing_family
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE."PUBLICATIONS"  src,
            LATERAL FLATTEN(INPUT => src."citation") cit
    JOIN    PATENTS_GOOGLE.PATENTS_GOOGLE."PUBLICATIONS"  tgt
           ON tgt."publication_number" = cit.value:"publication_number"::STRING
    JOIN    jan15 j
           ON tgt."family_id" = j."family_id"
    WHERE   cit.value:"publication_number" IS NOT NULL
)

SELECT
    j."family_id",
    j."earliest_pub_date",

    LISTAGG(DISTINCT pub."publication_number", ',')
        WITHIN GROUP (ORDER BY pub."publication_number")              AS "publication_numbers",

    LISTAGG(DISTINCT pub."country_code", ',')
        WITHIN GROUP (ORDER BY pub."country_code")                    AS "country_codes",

    LISTAGG(DISTINCT cpc."cpc_code", ',')
        WITHIN GROUP (ORDER BY cpc."cpc_code")                        AS "cpc_codes",

    LISTAGG(DISTINCT ipc."ipc_code", ',')
        WITHIN GROUP (ORDER BY ipc."ipc_code")                        AS "ipc_codes",

    LISTAGG(DISTINCT out.cited_family, ',')
        WITHIN GROUP (ORDER BY out.cited_family)                      AS "cites_family_ids",

    LISTAGG(DISTINCT inc.citing_family, ',')
        WITHIN GROUP (ORDER BY inc.citing_family)                     AS "cited_by_family_ids"

FROM           jan15                j
LEFT JOIN      pub_info             pub ON j."family_id" = pub."family_id"
LEFT JOIN      cpc_codes            cpc ON j."family_id" = cpc."family_id"
LEFT JOIN      ipc_codes            ipc ON j."family_id" = ipc."family_id"
LEFT JOIN      outgoing             out ON j."family_id" = out.source_family
LEFT JOIN      incoming             inc ON j."family_id" = inc.target_family

GROUP BY j."family_id", j."earliest_pub_date"
ORDER BY j."earliest_pub_date", j."family_id";