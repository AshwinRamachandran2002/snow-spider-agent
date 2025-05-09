WITH fams_201501 AS (      -- families whose first publication is in Jan-2015
    SELECT  "family_id",
            MIN("publication_date") AS "earliest_date"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE."PUBLICATIONS"
    GROUP BY "family_id"
    HAVING  MIN("publication_date") BETWEEN 20150101 AND 20150131
),
family_pubs AS (           -- all publications in those families
    SELECT  p."family_id",
            p."publication_number",
            p."country_code",
            p."cpc",
            p."ipc",
            p."citation"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE."PUBLICATIONS" p
    JOIN    fams_201501 f
           ON f."family_id" = p."family_id"
),
/* ---------- families that CITE any publication of the target families ---------- */
target_pubnums AS (
    SELECT DISTINCT "publication_number", "family_id" AS target_family
    FROM   family_pubs
),
citing_families AS (
    SELECT  DISTINCT
            tp.target_family,
            p2."family_id" AS citing_family
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE."PUBLICATIONS" p2,
            LATERAL FLATTEN(input => p2."citation") cit2,
            target_pubnums tp
    WHERE   cit2.value:"publication_number"::string = tp."publication_number"
      AND   p2."family_id" IS NOT NULL
),
/* ---------- families that ARE CITED by the target families ---------- */
cited_families AS (
    SELECT  DISTINCT
            fp."family_id" AS target_family,
            p3."family_id" AS cited_family
    FROM    family_pubs fp,
            LATERAL FLATTEN(input => fp."citation") cit,
            PATENTS_GOOGLE.PATENTS_GOOGLE."PUBLICATIONS" p3
    WHERE   p3."publication_number" = cit.value:"publication_number"::string
      AND   p3."family_id" IS NOT NULL
),
/* ---------- CPC / IPC codes flattened ---------- */
cpc_codes AS (
    SELECT  DISTINCT
            fp."family_id",
            cpc_f.value:"code"::string AS code
    FROM    family_pubs fp,
            LATERAL FLATTEN(input => fp."cpc") cpc_f
    WHERE   cpc_f.value:"code" IS NOT NULL
),
ipc_codes AS (
    SELECT  DISTINCT
            fp."family_id",
            ipc_f.value:"code"::string AS code
    FROM    family_pubs fp,
            LATERAL FLATTEN(input => fp."ipc") ipc_f
    WHERE   ipc_f.value:"code" IS NOT NULL
)
/* ---------- final aggregation ---------- */
SELECT  f."family_id",
        f."earliest_date",
        LISTAGG(DISTINCT fp."publication_number", ', ')
            WITHIN GROUP (ORDER BY fp."publication_number")    AS "publication_numbers",
        LISTAGG(DISTINCT fp."country_code", ', ')
            WITHIN GROUP (ORDER BY fp."country_code")          AS "country_codes",
        LISTAGG(DISTINCT cc.code, ', ')
            WITHIN GROUP (ORDER BY cc.code)                    AS "cpc_codes",
        LISTAGG(DISTINCT ic.code, ', ')
            WITHIN GROUP (ORDER BY ic.code)                    AS "ipc_codes",
        LISTAGG(DISTINCT cf.cited_family, ', ')
            WITHIN GROUP (ORDER BY cf.cited_family)            AS "cited_family_ids",
        LISTAGG(DISTINCT ct.citing_family, ', ')
            WITHIN GROUP (ORDER BY ct.citing_family)           AS "citing_family_ids"
FROM    fams_201501      f
LEFT JOIN family_pubs    fp  ON f."family_id" = fp."family_id"
LEFT JOIN cpc_codes      cc  ON f."family_id" = cc."family_id"
LEFT JOIN ipc_codes      ic  ON f."family_id" = ic."family_id"
LEFT JOIN cited_families cf  ON f."family_id" = cf.target_family
LEFT JOIN citing_families ct ON f."family_id" = ct.target_family
GROUP BY f."family_id", f."earliest_date"
ORDER BY f."family_id";