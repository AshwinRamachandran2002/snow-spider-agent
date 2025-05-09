WITH family_first_pub AS (          /* families whose first publication appeared in Jan-2015 */
    SELECT
        "family_id",
        MIN("publication_date") AS earliest_date
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    GROUP BY "family_id"
    HAVING MIN("publication_date") BETWEEN 20150101 AND 20150131
),

family_pubs AS (                    /* all publications in those families */
    SELECT p.*
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    JOIN family_first_pub f
      ON p."family_id" = f."family_id"
),

pubs_agg AS (                       /* publication numbers & country codes */
    SELECT
        "family_id",
        LISTAGG(DISTINCT "publication_number", ', ') WITHIN GROUP (ORDER BY "publication_number") AS publication_numbers,
        LISTAGG(DISTINCT "country_code", ', ')        WITHIN GROUP (ORDER BY "country_code")      AS country_codes
    FROM family_pubs
    GROUP BY "family_id"
),

cpc_codes AS (                      /* distinct CPC codes */
    SELECT
        fp."family_id",
        LISTAGG(DISTINCT c.value:"code"::STRING, ', ') WITHIN GROUP (ORDER BY c.value:"code"::STRING) AS cpc_codes
    FROM family_pubs fp,
         LATERAL FLATTEN (INPUT => fp."cpc") c
    GROUP BY fp."family_id"
),

ipc_codes AS (                      /* distinct IPC codes */
    SELECT
        fp."family_id",
        LISTAGG(DISTINCT i.value:"code"::STRING, ', ') WITHIN GROUP (ORDER BY i.value:"code"::STRING) AS ipc_codes
    FROM family_pubs fp,
         LATERAL FLATTEN (INPUT => fp."ipc") i
    GROUP BY fp."family_id"
),

cited_pub_numbers AS (              /* publications our family cites */
    SELECT
        fp."family_id"                         AS source_family,
        cit.value:"publication_number"::STRING AS cited_pub_number
    FROM family_pubs fp,
         LATERAL FLATTEN (INPUT => fp."citation") cit
    WHERE cit.value:"publication_number" IS NOT NULL
),

cited_families AS (                 /* families that are cited by our family */
    SELECT
        cpn.source_family AS "family_id",
        LISTAGG(DISTINCT p2."family_id", ', ') WITHIN GROUP (ORDER BY p2."family_id") AS families_cited
    FROM cited_pub_numbers cpn
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p2
      ON p2."publication_number" = cpn.cited_pub_number
    GROUP BY cpn.source_family
),

citing_relations AS (               /* other families that cite our publications */
    SELECT
        fp."family_id"      AS target_family,
        p_other."family_id" AS citing_family
    FROM family_pubs fp
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p_other
      ON p_other."family_id" <> fp."family_id"
    , LATERAL FLATTEN (INPUT => p_other."citation") cit
    WHERE cit.value:"publication_number"::STRING = fp."publication_number"
),

citing_families AS (
    SELECT
        target_family AS "family_id",
        LISTAGG(DISTINCT citing_family, ', ') WITHIN GROUP (ORDER BY citing_family) AS families_citing
    FROM citing_relations
    GROUP BY target_family
)

SELECT
    f."family_id",
    f.earliest_date,
    p.publication_numbers,
    p.country_codes,
    COALESCE(cpc.cpc_codes , '') AS cpc_codes,
    COALESCE(ipc.ipc_codes , '') AS ipc_codes,
    COALESCE(cf.families_cited , '') AS families_cited,
    COALESCE(ci.families_citing, '') AS families_citing
FROM family_first_pub  f
LEFT JOIN pubs_agg        p  ON f."family_id" = p."family_id"
LEFT JOIN cpc_codes       cpc ON f."family_id" = cpc."family_id"
LEFT JOIN ipc_codes       ipc ON f."family_id" = ipc."family_id"
LEFT JOIN cited_families  cf  ON f."family_id" = cf."family_id"
LEFT JOIN citing_families ci  ON f."family_id" = ci."family_id"
ORDER BY f."family_id";