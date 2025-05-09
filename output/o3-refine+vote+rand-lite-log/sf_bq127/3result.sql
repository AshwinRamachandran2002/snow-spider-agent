WITH fam_earliest AS (               /* families whose first publication is in Jan‑2015 */
    SELECT
        "family_id",
        MIN("publication_date") AS "earliest_date"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    GROUP BY "family_id"
    HAVING MIN("publication_date") BETWEEN 20150101 AND 20150131
),

/* every publication that belongs to the above families */
family_pubs AS (
    SELECT
        p."family_id",
        p."publication_number",
        p."country_code",
        p."cpc",
        p."ipc"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    JOIN fam_earliest fe
          ON p."family_id" = fe."family_id"
),

/* CPC codes that appear in those families */
cpc_codes AS (
    SELECT
        fp."family_id",
        c.value:"code"::STRING AS "code"
    FROM family_pubs fp,
         LATERAL FLATTEN(input => fp."cpc") c
    WHERE c.value:"code" IS NOT NULL
),

/* IPC codes that appear in those families */
ipc_codes AS (
    SELECT
        fp."family_id",
        i.value:"code"::STRING AS "code"
    FROM family_pubs fp,
         LATERAL FLATTEN(input => fp."ipc") i
    WHERE i.value:"code" IS NOT NULL
),

/* every single citation pair in the publications table */
all_citations AS (
    SELECT
        p."publication_number"                        AS "citing_pub",
        p."family_id"                                 AS "citing_family",
        ct.value:"publication_number"::STRING         AS "cited_pub"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."citation") ct
    WHERE ct.value:"publication_number" IS NOT NULL
),

/* families that OUR target families cite */
family_cited AS (
    SELECT DISTINCT
        fe."family_id"       AS "src_family",
        pub2."family_id"     AS "cited_family"
    FROM fam_earliest fe
    JOIN family_pubs  fp   ON fp."family_id"   = fe."family_id"
    JOIN all_citations ac  ON ac."citing_pub" = fp."publication_number"
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS pub2
         ON pub2."publication_number" = ac."cited_pub"
    WHERE pub2."family_id" <> fe."family_id"
),

/* families that cite OUR target families */
family_citing AS (
    SELECT DISTINCT
        fe."family_id"      AS "tgt_family",
        ac."citing_family"  AS "citing_family"
    FROM fam_earliest fe
    JOIN family_pubs  fp ON fp."family_id" = fe."family_id"
    JOIN all_citations ac ON ac."cited_pub" = fp."publication_number"
    WHERE ac."citing_family" <> fe."family_id"
)

SELECT
    fe."family_id",
    fe."earliest_date"                                           AS "earliest_publication_date",

    LISTAGG(DISTINCT fp."publication_number", ',')
        WITHIN GROUP (ORDER BY fp."publication_number")          AS "publication_numbers",

    LISTAGG(DISTINCT fp."country_code", ',')
        WITHIN GROUP (ORDER BY fp."country_code")                AS "country_codes",

    LISTAGG(DISTINCT cpc."code", ',')
        WITHIN GROUP (ORDER BY cpc."code")                       AS "cpc_codes",

    LISTAGG(DISTINCT ipc."code", ',')
        WITHIN GROUP (ORDER BY ipc."code")                       AS "ipc_codes",

    LISTAGG(DISTINCT fc."cited_family", ',')
        WITHIN GROUP (ORDER BY fc."cited_family")                AS "families_cited",

    LISTAGG(DISTINCT fci."citing_family", ',')
        WITHIN GROUP (ORDER BY fci."citing_family")              AS "families_citing"

FROM fam_earliest   fe
LEFT JOIN family_pubs   fp  ON fp."family_id" = fe."family_id"
LEFT JOIN cpc_codes     cpc ON cpc."family_id" = fe."family_id"
LEFT JOIN ipc_codes     ipc ON ipc."family_id" = fe."family_id"
LEFT JOIN family_cited  fc  ON fc."src_family" = fe."family_id"
LEFT JOIN family_citing fci ON fci."tgt_family" = fe."family_id"

GROUP BY fe."family_id", fe."earliest_date"
ORDER BY fe."family_id";