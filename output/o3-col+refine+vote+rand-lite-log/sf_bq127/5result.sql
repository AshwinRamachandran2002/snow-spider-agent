WITH jan15_fams AS (                 -- families whose 1st publication is in Jan-2015
    SELECT  "family_id",
            MIN("publication_date")                          AS "first_pub_date"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    GROUP BY "family_id"
    HAVING  MIN("publication_date") BETWEEN 20150101 AND 20150131
),

jan15_pub_full AS (                 -- all publication rows for those families
    SELECT  p.*
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    JOIN    jan15_fams f
           ON p."family_id" = f."family_id"
),

jan15_pubs AS (                     -- only the columns we need repeatedly
    SELECT  "family_id",
            "publication_number",
            "country_code"
    FROM    jan15_pub_full
),

jan15_codes AS (                    -- flatten CPC & IPC codes
    SELECT  pf."family_id",
            cpc.value:"code"::STRING   AS "cpc_code",
            NULL                      AS "ipc_code"
    FROM    jan15_pub_full pf,
            LATERAL FLATTEN (INPUT => pf."cpc")  cpc
    UNION ALL
    SELECT  pf."family_id",
            NULL,
            ipc.value:"code"::STRING
    FROM    jan15_pub_full pf,
            LATERAL FLATTEN (INPUT => pf."ipc")  ipc
),

fam_cites AS (                      -- Jan-2015 families → other families they cite
    SELECT DISTINCT
           pf."family_id"                         AS "citing_family",
           pub2."family_id"                      AS "cited_family"
    FROM   jan15_pub_full pf,
           LATERAL FLATTEN (INPUT => pf."citation") cit
    JOIN   PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS pub2
          ON pub2."publication_number" = cit.value:"publication_number"::STRING
    WHERE  pub2."family_id" IS NOT NULL
),

fam_cited_by AS (                   -- other families → Jan-2015 families they cite
    SELECT DISTINCT
           pub2."family_id"                      AS "citing_family",
           pf."family_id"                        AS "cited_family"
    FROM   PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS pub2,
           LATERAL FLATTEN (INPUT => pub2."citation") cit
    JOIN   jan15_pub_full pf
          ON pf."publication_number" = cit.value:"publication_number"::STRING
    WHERE  pub2."family_id" IS NOT NULL
)

SELECT
        f."family_id",
        TO_VARCHAR(f."first_pub_date")                                                AS "first_publication_date",
        LISTAGG(DISTINCT p."publication_number", ',')
             WITHIN GROUP (ORDER BY p."publication_number")                           AS "publication_numbers",
        LISTAGG(DISTINCT p."country_code", ',')
             WITHIN GROUP (ORDER BY p."country_code")                                 AS "country_codes",
        LISTAGG(DISTINCT c."cpc_code", ',')
             WITHIN GROUP (ORDER BY c."cpc_code")                                     AS "cpc_codes",
        LISTAGG(DISTINCT c."ipc_code", ',')
             WITHIN GROUP (ORDER BY c."ipc_code")                                     AS "ipc_codes",
        LISTAGG(DISTINCT fc."cited_family", ',')
             WITHIN GROUP (ORDER BY fc."cited_family")                                AS "families_cited_by_this",
        LISTAGG(DISTINCT fb."citing_family", ',')
             WITHIN GROUP (ORDER BY fb."citing_family")                               AS "families_citing_this"
FROM    jan15_fams        f
LEFT JOIN jan15_pubs      p  ON p."family_id" = f."family_id"
LEFT JOIN jan15_codes     c  ON c."family_id" = f."family_id"
LEFT JOIN fam_cites       fc ON fc."citing_family" = f."family_id"
LEFT JOIN fam_cited_by    fb ON fb."cited_family"  = f."family_id"
GROUP BY f."family_id", f."first_pub_date"
ORDER BY f."family_id";