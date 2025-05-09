/* --------------------------------------------------------------------------
   Earliest-Jan-2015 families together with
   • earliest publication date
   • all publication numbers & country codes
   • distinct CPC & IPC codes
   • distinct family-ids that CITE this family      (cited_by_families)
   • distinct family-ids that are CITED by this family (families_cited_by_this)
   All list fields are comma-separated and alphabetically ordered
---------------------------------------------------------------------------*/
WITH jan15_families AS (   --------------------------------------------------
    SELECT  "family_id",
            MIN("publication_date")                                              AS "earliest_pub_date"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    GROUP BY "family_id"
    HAVING  MIN("publication_date") BETWEEN 20150101 AND 20150131
),
/* ---------- aggregate publication numbers & country codes ---------------- */
pubs_agg AS (
    SELECT  "family_id",
            LISTAGG(DISTINCT "publication_number", ',')
                WITHIN GROUP (ORDER BY "publication_number")                    AS "publication_numbers",
            LISTAGG(DISTINCT "country_code", ',')
                WITHIN GROUP (ORDER BY "country_code")                          AS "country_codes"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    GROUP BY "family_id"
),
/* ------------------------ CPC & IPC code lists --------------------------- */
cpc_codes AS (
    SELECT  p."family_id",
            LISTAGG(DISTINCT c.value:"code"::STRING, ',')
                WITHIN GROUP (ORDER BY c.value:"code"::STRING)                  AS "cpc_codes"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    CROSS   JOIN LATERAL FLATTEN(input => p."cpc") c
    WHERE   c.value:"code" IS NOT NULL
    GROUP BY p."family_id"
),
ipc_codes AS (
    SELECT  p."family_id",
            LISTAGG(DISTINCT i.value:"code"::STRING, ',')
                WITHIN GROUP (ORDER BY i.value:"code"::STRING)                  AS "ipc_codes"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    CROSS   JOIN LATERAL FLATTEN(input => p."ipc") i
    WHERE   i.value:"code" IS NOT NULL
    GROUP BY p."family_id"
),
/* ---------------------------- citation network --------------------------- */
all_citations AS (   -- publication-level citations
    SELECT  p."family_id"                                                    AS "citing_family_id",
            c.value:"publication_number"::STRING                             AS "cited_pub_number"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    CROSS   JOIN LATERAL FLATTEN(input => p."citation") c
    WHERE   c.value:"publication_number" IS NOT NULL
),
citations_fam AS (   -- mapped to family-ids on both sides
    SELECT  ac."citing_family_id",
            pub."family_id"                                                  AS "cited_family_id"
    FROM    all_citations ac
    JOIN    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS  pub
           ON pub."publication_number" = ac."cited_pub_number"
),
families_cited_by AS (   -- out-links for each family
    SELECT  "citing_family_id"                                               AS "family_id",
            LISTAGG( DISTINCT "cited_family_id", ',')
                WITHIN GROUP (ORDER BY "cited_family_id")                    AS "families_cited_by_this"
    FROM    citations_fam
    GROUP BY "citing_family_id"
),
families_citing AS (    -- in-links for each family
    SELECT  "cited_family_id"                                                AS "family_id",
            LISTAGG( DISTINCT "citing_family_id", ',')
                WITHIN GROUP (ORDER BY "citing_family_id")                   AS "cited_by_families"
    FROM    citations_fam
    GROUP BY "cited_family_id"
)
/* --------------------------- final assembly ------------------------------ */
SELECT  jf."family_id",
        jf."earliest_pub_date",
        pa."publication_numbers",
        pa."country_codes",
        COALESCE(cc."cpc_codes"        , '')                                  AS "cpc_codes",
        COALESCE(ic."ipc_codes"        , '')                                  AS "ipc_codes",
        COALESCE(ci."cited_by_families", '')                                  AS "cited_by_families",
        COALESCE(co."families_cited_by_this", '')                             AS "families_cited_by_this"
FROM        jan15_families               jf
LEFT JOIN   pubs_agg          pa  ON pa."family_id" = jf."family_id"
LEFT JOIN   cpc_codes         cc  ON cc."family_id" = jf."family_id"
LEFT JOIN   ipc_codes         ic  ON ic."family_id" = jf."family_id"
LEFT JOIN   families_citing   ci  ON ci."family_id" = jf."family_id"
LEFT JOIN   families_cited_by co  ON co."family_id" = jf."family_id"
ORDER BY    jf."family_id";