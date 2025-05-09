/*  Publication families whose first (earliest) publication occurred
    between 1 Jan 2015 and 31 Jan 2015 – together with
    publications, countries, CPC, IPC, cited and citing families
*/
WITH base AS (   -- families whose earliest publication is in Jan‑2015
    SELECT  "family_id",
            MIN("publication_date") AS "earliest_pub_date"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE."PUBLICATIONS"
    GROUP BY "family_id"
    HAVING  MIN("publication_date") BETWEEN 20150101 AND 20150131
),

/* ----------  aggregated publication numbers & countries  ---------- */
pubs AS (
    SELECT  "family_id",
            LISTAGG(DISTINCT "publication_number", ',')
                 WITHIN GROUP (ORDER BY "publication_number")        AS "pub_numbers",
            LISTAGG(DISTINCT "country_code", ',')
                 WITHIN GROUP (ORDER BY "country_code")              AS "country_codes"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE."PUBLICATIONS"
    WHERE   "family_id" IN (SELECT "family_id" FROM base)
    GROUP BY "family_id"
),

/* ----------  aggregated CPC codes  ---------- */
cpc AS (
    SELECT  p."family_id",
            LISTAGG(DISTINCT c.value:"code"::STRING, ',')
                 WITHIN GROUP (ORDER BY c.value:"code"::STRING)      AS "cpc_codes"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE."PUBLICATIONS"  p
            JOIN base b ON p."family_id" = b."family_id"
            CROSS JOIN LATERAL FLATTEN(
                   INPUT => p."cpc",
                   OUTER => TRUE) c
    WHERE   c.value:"code" IS NOT NULL
    GROUP BY p."family_id"
),

/* ----------  aggregated IPC codes  ---------- */
ipc AS (
    SELECT  p."family_id",
            LISTAGG(DISTINCT i.value:"code"::STRING, ',')
                 WITHIN GROUP (ORDER BY i.value:"code"::STRING)      AS "ipc_codes"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE."PUBLICATIONS"  p
            JOIN base b ON p."family_id" = b."family_id"
            CROSS JOIN LATERAL FLATTEN(
                   INPUT => p."ipc",
                   OUTER => TRUE) i
    WHERE   i.value:"code" IS NOT NULL
    GROUP BY p."family_id"
),

/* ----------  outbound citations (families that a family cites)  ---------- */
cited AS (
    SELECT  DISTINCT
            p."family_id"                  AS "source_family",
            cited_p."family_id"            AS "cited_family"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE."PUBLICATIONS"  p
            JOIN base b ON p."family_id" = b."family_id"
            CROSS JOIN LATERAL FLATTEN(INPUT => p."citation") c
            LEFT JOIN PATENTS_GOOGLE.PATENTS_GOOGLE."PUBLICATIONS"  cited_p
                   ON cited_p."publication_number" = c.value:"publication_number"::STRING
    WHERE   cited_p."family_id" IS NOT NULL
),
cited_agg AS (
    SELECT  "source_family" AS "family_id",
            LISTAGG(DISTINCT "cited_family", ',')
                 WITHIN GROUP (ORDER BY "cited_family")             AS "cited_families"
    FROM    cited
    GROUP BY "source_family"
),

/* ----------  inbound citations (families that cite a family)  ---------- */
selected_pubs AS (      -- all publication numbers of the Jan‑2015 families
    SELECT  "publication_number",
            "family_id"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE."PUBLICATIONS"
    WHERE   "family_id" IN (SELECT "family_id" FROM base)
),
citing AS (
    SELECT  DISTINCT
            src."family_id"               AS "citing_family",
            sp."family_id"                AS "target_family"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE."PUBLICATIONS"  src
            CROSS JOIN LATERAL FLATTEN(INPUT => src."citation") c
            JOIN selected_pubs            sp
                 ON sp."publication_number" = c.value:"publication_number"::STRING
    WHERE   src."family_id" <> sp."family_id"   -- exclude self‑citations
),
citing_agg AS (
    SELECT  "target_family" AS "family_id",
            LISTAGG(DISTINCT "citing_family", ',')
                 WITHIN GROUP (ORDER BY "citing_family")            AS "citing_families"
    FROM    citing
    GROUP BY "target_family"
)

/* ======================  final output  ====================== */
SELECT  b."family_id",
        b."earliest_pub_date",
        p."pub_numbers",
        p."country_codes",
        cpc."cpc_codes",
        ipc."ipc_codes",
        COALESCE(cited_agg."cited_families", '')   AS "cited_families",
        COALESCE(citing_agg."citing_families", '') AS "citing_families"
FROM    base            b
        LEFT JOIN pubs        p   ON p."family_id"       = b."family_id"
        LEFT JOIN cpc         ON cpc."family_id"         = b."family_id"
        LEFT JOIN ipc         ON ipc."family_id"         = b."family_id"
        LEFT JOIN cited_agg   ON cited_agg."family_id"   = b."family_id"
        LEFT JOIN citing_agg  ON citing_agg."family_id"  = b."family_id"
ORDER BY b."earliest_pub_date", b."family_id";