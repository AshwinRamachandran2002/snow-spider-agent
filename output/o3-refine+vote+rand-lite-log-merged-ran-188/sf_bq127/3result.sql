/*  Families whose first-ever publication appeared in January-2015,
    together with the requested aggregated information                    */

WITH first_pub AS (          -- earliest publication per family
    SELECT  "family_id",
            MIN("publication_date") AS "earliest_pubdate"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    GROUP BY "family_id"
),

jan15_family AS (            -- keep only those first published in Jan-2015
    SELECT  *
    FROM    first_pub
    WHERE   "earliest_pubdate" BETWEEN 20150101 AND 20150131
),

/* ----------  publications that belong to the January-2015 families ---------- */
pubs AS (
    SELECT  p."family_id",
            p."publication_number",
            p."country_code"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    JOIN    jan15_family jf
      ON    p."family_id" = jf."family_id"
),

/* ----------  CPC / IPC codes (flatten JSON arrays) ------------------------- */
cpc_codes AS (
    SELECT  p."family_id",
            f.value:"code"::STRING AS "cpc_code"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    JOIN    jan15_family jf
      ON    p."family_id" = jf."family_id",
            LATERAL FLATTEN (INPUT => p."cpc") f
    WHERE   f.value:"code" IS NOT NULL
),

ipc_codes AS (
    SELECT  p."family_id",
            f.value:"code"::STRING AS "ipc_code"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    JOIN    jan15_family jf
      ON    p."family_id" = jf."family_id",
            LATERAL FLATTEN (INPUT => p."ipc") f
    WHERE   f.value:"code" IS NOT NULL
),

/* ----------  families that are *cited by* each January-2015 family ---------- */
cited_pub_numbers AS (
    SELECT  p."family_id"                       AS "src_family",
            c.value:"publication_number"::STRING AS "cited_pub"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    JOIN    jan15_family jf
      ON    p."family_id" = jf."family_id",
            LATERAL FLATTEN (INPUT => p."citation") c
    WHERE   c.value:"publication_number" IS NOT NULL
),

cited_families AS (
    SELECT  DISTINCT
            cp."src_family"        AS "family_id",
            p2."family_id"         AS "cited_family_id"
    FROM    cited_pub_numbers cp
    JOIN    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p2
      ON    p2."publication_number" = cp."cited_pub"
),

/* ----------  families that *cite* any publication of a January-2015 family -- */
family_pub_numbers AS (
    SELECT  "family_id", "publication_number"
    FROM    pubs
),

citing_families AS (
    SELECT  DISTINCT
            fp."family_id"                 AS "family_id",
            pc."family_id"                 AS "citing_family_id"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS pc,
            LATERAL FLATTEN (INPUT => pc."citation") cit
    JOIN    family_pub_numbers fp
      ON    cit.value:"publication_number"::STRING = fp."publication_number"
    WHERE   pc."family_id" <> fp."family_id"      -- exclude self-citations
)

/* ----------  assemble final result ----------------------------------------- */
SELECT
        jf."family_id",
        jf."earliest_pubdate",

        /* publication numbers & country codes */
        ARRAY_TO_STRING(
            ARRAY_SORT(ARRAY_AGG(DISTINCT pubs."publication_number")),
            ','
        )                                                   AS "publication_numbers",

        ARRAY_TO_STRING(
            ARRAY_SORT(ARRAY_AGG(DISTINCT pubs."country_code")),
            ','
        )                                                   AS "country_codes",

        /* CPC / IPC codes */
        ARRAY_TO_STRING(
            ARRAY_SORT(ARRAY_AGG(DISTINCT cpc_codes."cpc_code")),
            ','
        )                                                   AS "cpc_codes",

        ARRAY_TO_STRING(
            ARRAY_SORT(ARRAY_AGG(DISTINCT ipc_codes."ipc_code")),
            ','
        )                                                   AS "ipc_codes",

        /* families *cited by* this family */
        ARRAY_TO_STRING(
            ARRAY_SORT(ARRAY_AGG(DISTINCT cited_families."cited_family_id")),
            ','
        )                                                   AS "cited_family_ids",

        /* families that *cite* this family */
        ARRAY_TO_STRING(
            ARRAY_SORT(ARRAY_AGG(DISTINCT citing_families."citing_family_id")),
            ','
        )                                                   AS "citing_family_ids"

FROM    jan15_family jf
LEFT JOIN pubs            ON jf."family_id" = pubs."family_id"
LEFT JOIN cpc_codes       ON jf."family_id" = cpc_codes."family_id"
LEFT JOIN ipc_codes       ON jf."family_id" = ipc_codes."family_id"
LEFT JOIN cited_families  ON jf."family_id" = cited_families."family_id"
LEFT JOIN citing_families ON jf."family_id" = citing_families."family_id"

GROUP BY jf."family_id", jf."earliest_pubdate"
ORDER BY jf."earliest_pubdate", jf."family_id";