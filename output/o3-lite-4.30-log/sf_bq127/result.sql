WITH base AS (                                            -- families first published in Jan‑2015
    SELECT
        "family_id",
        MIN("publication_date") AS earliest_publication_date
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    GROUP BY "family_id"
    HAVING MIN("publication_date") BETWEEN 20150101 AND 20150131
),
pubs AS (                                                 -- all publications of those families
    SELECT p.*
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    JOIN base b ON b."family_id" = p."family_id"
),
cpc_flat AS (                                             -- CPC codes
    SELECT
        p."family_id",
        COALESCE(f.value:"code"::STRING, f.value::STRING) AS cpc_code
    FROM pubs p,
         LATERAL FLATTEN(input => p."cpc") f
    WHERE COALESCE(f.value:"code"::STRING, f.value::STRING) IS NOT NULL
),
ipc_flat AS (                                             -- IPC codes
    SELECT
        p."family_id",
        COALESCE(f.value:"code"::STRING, f.value::STRING) AS ipc_code
    FROM pubs p,
         LATERAL FLATTEN(input => p."ipc") f
    WHERE COALESCE(f.value:"code"::STRING, f.value::STRING) IS NOT NULL
),
cited_flat AS (                                           -- families this family cites
    SELECT DISTINCT
        src."family_id" AS source_family_id,
        tgt."family_id" AS cited_family_id
    FROM pubs src,
         LATERAL FLATTEN(input => src."citation") f,
         PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS tgt
    WHERE tgt."publication_number" = COALESCE(f.value:"publication_number"::STRING,
                                              f.value::STRING)
),
citing_flat AS (                                          -- families that cite this family
    SELECT DISTINCT
        cit."family_id" AS citing_family_id,
        tgt."family_id" AS target_family_id
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS cit,
         LATERAL FLATTEN(input => cit."citation") f,
         pubs tgt
    WHERE tgt."publication_number" = COALESCE(f.value:"publication_number"::STRING,
                                              f.value::STRING)
      AND cit."family_id" IS NOT NULL
)
SELECT
    b.earliest_publication_date                                                             AS earliest_publication_date,
    LISTAGG(DISTINCT p."publication_number", ', ') WITHIN GROUP (ORDER BY p."publication_number") AS publication_numbers,
    LISTAGG(DISTINCT p."country_code",       ', ') WITHIN GROUP (ORDER BY p."country_code")       AS country_codes,
    LISTAGG(DISTINCT c.cpc_code,             ', ') WITHIN GROUP (ORDER BY c.cpc_code)             AS cpc_codes,
    LISTAGG(DISTINCT i.ipc_code,             ', ') WITHIN GROUP (ORDER BY i.ipc_code)             AS ipc_codes,
    LISTAGG(DISTINCT cf.citing_family_id,    ', ') WITHIN GROUP (ORDER BY cf.citing_family_id)    AS citing_family_ids,
    LISTAGG(DISTINCT cd.cited_family_id,     ', ') WITHIN GROUP (ORDER BY cd.cited_family_id)     AS cited_family_ids
FROM base b
LEFT JOIN pubs        p  ON p."family_id" = b."family_id"
LEFT JOIN cpc_flat    c  ON c."family_id" = b."family_id"
LEFT JOIN ipc_flat    i  ON i."family_id" = b."family_id"
LEFT JOIN citing_flat cf ON cf.target_family_id = b."family_id"
LEFT JOIN cited_flat  cd ON cd.source_family_id  = b."family_id"
GROUP BY
    b."family_id",
    b.earliest_publication_date
ORDER BY
    b.earliest_publication_date;