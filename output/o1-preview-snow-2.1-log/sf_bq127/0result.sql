SELECT
    "family_id",
    "earliest_publication_date",
    "publication_numbers",
    "country_codes",
    "cpc_codes",
    "ipc_codes",
    "citing_families",
    "cited_by_families"
FROM (
    WITH earliest_publications AS (
        SELECT
            "family_id",
            MIN("publication_date") AS "earliest_publication_date"
        FROM
            PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
        GROUP BY
            "family_id"
        HAVING
            MIN("publication_date") BETWEEN 20150101 AND 20150131
    ), family_publications AS (
        SELECT 
            p."family_id",
            p."publication_number",
            p."country_code",
            p."cpc",
            p."ipc",
            p."citation"
        FROM
            PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
        INNER JOIN
            earliest_publications ep
        ON
            p."family_id" = ep."family_id"
    ), cpc_codes AS (
        SELECT DISTINCT
            fp."family_id",
            LOWER(TRIM(c.value:"code"::STRING)) AS "cpc_code"
        FROM
            family_publications fp
        , LATERAL FLATTEN(input => fp."cpc") c
    ), ipc_codes AS (
        SELECT DISTINCT
            fp."family_id",
            LOWER(TRIM(i.value:"code"::STRING)) AS "ipc_code"
        FROM
            family_publications fp
        , LATERAL FLATTEN(input => fp."ipc") i
    ), citations_made AS (
        SELECT DISTINCT
            fp."family_id" AS "citing_family_id",
            c.value:"publication_number"::STRING AS "cited_publication_number"
        FROM
            family_publications fp
        , LATERAL FLATTEN(input => fp."citation") c
        WHERE
            c.value:"publication_number"::STRING IS NOT NULL
    ), cited_families AS (
        SELECT DISTINCT
            cm."citing_family_id",
            p2."family_id" AS "cited_family_id"
        FROM
            citations_made cm
        INNER JOIN
            PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p2
        ON
            cm."cited_publication_number" = p2."publication_number"
        WHERE
            p2."family_id" IS NOT NULL
    ), citing_publications AS (
        SELECT DISTINCT
            p."family_id" AS "citing_family_id",
            c.value:"publication_number"::STRING AS "cited_publication_number"
        FROM
            PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
        , LATERAL FLATTEN(input => p."citation") c
        WHERE
            c.value:"publication_number"::STRING IS NOT NULL
    ), our_publication_numbers AS (
        SELECT DISTINCT
            "family_id",
            "publication_number"
        FROM
            family_publications
    ), cited_by_families AS (
        SELECT DISTINCT
            cp."citing_family_id",
            opn."family_id" AS "our_family_id"
        FROM
            citing_publications cp
        INNER JOIN
            our_publication_numbers opn
        ON
            cp."cited_publication_number" = opn."publication_number"
        WHERE
            opn."family_id" IS NOT NULL
    ), result AS (
        SELECT
            ep."family_id",
            ep."earliest_publication_date",
            LISTAGG(DISTINCT fp."publication_number", ',') WITHIN GROUP (ORDER BY fp."publication_number") AS "publication_numbers",
            LISTAGG(DISTINCT fp."country_code", ',') WITHIN GROUP (ORDER BY fp."country_code") AS "country_codes",
            LISTAGG(DISTINCT cpc."cpc_code", ',') WITHIN GROUP (ORDER BY LEFT(cpc."cpc_code",1), cpc."cpc_code") AS "cpc_codes",
            LISTAGG(DISTINCT ipc."ipc_code", ',') WITHIN GROUP (ORDER BY LEFT(ipc."ipc_code",1), ipc."ipc_code") AS "ipc_codes",
            LISTAGG(DISTINCT cf."cited_family_id", ',') WITHIN GROUP (ORDER BY cf."cited_family_id") AS "citing_families",
            LISTAGG(DISTINCT cbf."citing_family_id", ',') WITHIN GROUP (ORDER BY cbf."citing_family_id") AS "cited_by_families"
        FROM
            earliest_publications ep
        LEFT JOIN
            family_publications fp
        ON
            ep."family_id" = fp."family_id"
        LEFT JOIN
            cpc_codes cpc
        ON
            ep."family_id" = cpc."family_id"
        LEFT JOIN
            ipc_codes ipc
        ON
            ep."family_id" = ipc."family_id"
        LEFT JOIN
            cited_families cf
        ON
            ep."family_id" = cf."citing_family_id"
        LEFT JOIN
            cited_by_families cbf
        ON
            ep."family_id" = cbf."our_family_id"
        GROUP BY
            ep."family_id",
            ep."earliest_publication_date"
    )
    SELECT
        "family_id",
        "earliest_publication_date",
        "publication_numbers",
        "country_codes",
        "cpc_codes",
        "ipc_codes",
        "citing_families",
        "cited_by_families"
    FROM
        result
);