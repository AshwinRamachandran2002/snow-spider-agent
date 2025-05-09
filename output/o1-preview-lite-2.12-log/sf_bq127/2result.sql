WITH jan2015_families AS (
    SELECT
        "family_id",
        MIN("publication_date") AS "earliest_publication_date"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    GROUP BY "family_id"
    HAVING MIN("publication_date") BETWEEN 20150101 AND 20150131
),
family_publications AS (
    SELECT
        p.*
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    JOIN jan2015_families f ON p."family_id" = f."family_id"
),
publication_numbers AS (
    SELECT
        "family_id",
        LISTAGG(DISTINCT "publication_number", ',' ) WITHIN GROUP (ORDER BY SUBSTR("publication_number",1,1), "publication_number") AS "publication_numbers"
    FROM family_publications
    GROUP BY "family_id"
),
country_codes AS (
    SELECT
        "family_id",
        LISTAGG(DISTINCT "country_code", ',') WITHIN GROUP (ORDER BY SUBSTR("country_code",1,1), "country_code") AS "country_codes"
    FROM family_publications
    GROUP BY "family_id"
),
publication_cpc AS (
    SELECT
        fp."family_id",
        c.value:"code"::STRING AS "cpc_code"
    FROM family_publications fp,
    LATERAL FLATTEN(input => fp."cpc") c
),
cpc_codes AS (
    SELECT
        "family_id",
        LISTAGG(DISTINCT "cpc_code", ',') WITHIN GROUP (ORDER BY SUBSTR("cpc_code",1,1), "cpc_code") AS "cpc_codes"
    FROM publication_cpc
    GROUP BY "family_id"
),
publication_ipc AS (
    SELECT
        fp."family_id",
        i.value:"code"::STRING AS "ipc_code"
    FROM family_publications fp,
    LATERAL FLATTEN(input => fp."ipc") i
),
ipc_codes AS (
    SELECT
        "family_id",
        LISTAGG(DISTINCT "ipc_code", ',') WITHIN GROUP (ORDER BY SUBSTR("ipc_code",1,1), "ipc_code") AS "ipc_codes"
    FROM publication_ipc
    GROUP BY "family_id"
),
family_citations AS (
    SELECT
        fp."family_id" AS "citing_family_id",
        c.value:"publication_number"::STRING AS "cited_publication_number"
    FROM family_publications fp,
    LATERAL FLATTEN(input => fp."citation") c
),
cited_families AS (
    SELECT
        fc."citing_family_id",
        cp."family_id" AS "cited_family_id"
    FROM family_citations fc
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS cp
        ON UPPER(REPLACE(cp."publication_number", '-', '')) = UPPER(REPLACE(fc."cited_publication_number", '-', ''))
),
cited_families_agg AS (
    SELECT
        "citing_family_id" AS "family_id",
        LISTAGG(DISTINCT "cited_family_id", ',') WITHIN GROUP (ORDER BY SUBSTR("cited_family_id",1,1), "cited_family_id") AS "cited_families"
    FROM cited_families
    GROUP BY "citing_family_id"
),
family_cited_by AS (
    SELECT
        fp."family_id" AS "cited_family_id",
        cp."family_id" AS "citing_family_id"
    FROM family_publications fp
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB a
        ON UPPER(REPLACE(a."publication_number", '-', '')) = UPPER(REPLACE(fp."publication_number", '-', ''))
    CROSS JOIN LATERAL FLATTEN(input => a."cited_by") cb
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS cp
        ON UPPER(REPLACE(cp."publication_number", '-', '')) = UPPER(REPLACE(cb.value:"publication_number"::STRING, '-', ''))
),
citing_families_agg AS (
    SELECT
        "cited_family_id" AS "family_id",
        LISTAGG(DISTINCT "citing_family_id", ',') WITHIN GROUP (ORDER BY SUBSTR("citing_family_id",1,1), "citing_family_id") AS "cited_by_families"
    FROM family_cited_by
    GROUP BY "cited_family_id"
)
SELECT
    CAST(f."family_id" AS STRING) AS "family_id",
    f."earliest_publication_date",
    CAST(pn."publication_numbers" AS STRING) AS "publication_numbers",
    CAST(cc."country_codes" AS STRING) AS "country_codes",
    CAST(cpc."cpc_codes" AS STRING) AS "cpc_codes",
    CAST(ipc."ipc_codes" AS STRING) AS "ipc_codes",
    CAST(cf."cited_families" AS STRING) AS "cited_families",
    CAST(cf2."cited_by_families" AS STRING) AS "cited_by_families"
FROM jan2015_families f
LEFT JOIN publication_numbers pn ON f."family_id" = pn."family_id"
LEFT JOIN country_codes cc ON f."family_id" = cc."family_id"
LEFT JOIN cpc_codes cpc ON f."family_id" = cpc."family_id"
LEFT JOIN ipc_codes ipc ON f."family_id" = ipc."family_id"
LEFT JOIN cited_families_agg cf ON f."family_id" = cf."family_id"
LEFT JOIN citing_families_agg cf2 ON f."family_id" = cf2."family_id";