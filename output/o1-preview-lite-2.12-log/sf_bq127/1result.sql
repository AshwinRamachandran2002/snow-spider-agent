WITH jan2015_families AS (
    SELECT "family_id", MIN("publication_date") AS "earliest_publication_date"
    FROM "PATENTS_GOOGLE"."PATENTS_GOOGLE"."PUBLICATIONS"
    GROUP BY "family_id"
    HAVING MIN("publication_date") BETWEEN 20150101 AND 20150131
),
family_pub_data AS (
    SELECT
        p."family_id",
        LISTAGG(DISTINCT p."publication_number", ',') WITHIN GROUP (ORDER BY p."publication_number") AS "publication_numbers",
        LISTAGG(DISTINCT p."country_code", ',') WITHIN GROUP (ORDER BY p."country_code") AS "country_codes"
    FROM "PATENTS_GOOGLE"."PATENTS_GOOGLE"."PUBLICATIONS" p
    WHERE p."family_id" IN (SELECT "family_id" FROM jan2015_families)
    GROUP BY p."family_id"
),
family_cpc_data AS (
    SELECT
        p."family_id",
        LISTAGG(DISTINCT c.value:"code"::STRING, ',') WITHIN GROUP (ORDER BY SUBSTRING(c.value:"code"::STRING, 1, 1), c.value:"code"::STRING) AS "cpc_codes"
    FROM "PATENTS_GOOGLE"."PATENTS_GOOGLE"."PUBLICATIONS" p
    JOIN LATERAL FLATTEN(input => p."cpc") c
    WHERE p."family_id" IN (SELECT "family_id" FROM jan2015_families)
    GROUP BY p."family_id"
),
family_ipc_data AS (
    SELECT
        p."family_id",
        LISTAGG(DISTINCT i.value:"code"::STRING, ',') WITHIN GROUP (ORDER BY SUBSTRING(i.value:"code"::STRING, 1, 1), i.value:"code"::STRING) AS "ipc_codes"
    FROM "PATENTS_GOOGLE"."PATENTS_GOOGLE"."PUBLICATIONS" p
    JOIN LATERAL FLATTEN(input => p."ipc") i
    WHERE p."family_id" IN (SELECT "family_id" FROM jan2015_families)
    GROUP BY p."family_id"
),
family_cited_data AS (
    SELECT
        p."family_id",
        LISTAGG(DISTINCT c_publ."family_id", ',') WITHIN GROUP (ORDER BY c_publ."family_id") AS "cited_families"
    FROM "PATENTS_GOOGLE"."PATENTS_GOOGLE"."PUBLICATIONS" p
    JOIN LATERAL FLATTEN(input => p."citation") c
    JOIN "PATENTS_GOOGLE"."PATENTS_GOOGLE"."PUBLICATIONS" c_publ
        ON c.value:"publication_number"::STRING = c_publ."publication_number"
    WHERE p."family_id" IN (SELECT "family_id" FROM jan2015_families)
    GROUP BY p."family_id"
),
family_citing_data AS (
    SELECT
        p."family_id",
        LISTAGG(DISTINCT citing_publ."family_id", ',') WITHIN GROUP (ORDER BY citing_publ."family_id") AS "cited_by_families"
    FROM "PATENTS_GOOGLE"."PATENTS_GOOGLE"."PUBLICATIONS" p
    JOIN "PATENTS_GOOGLE"."PATENTS_GOOGLE"."ABS_AND_EMB" a ON p."publication_number" = a."publication_number"
    JOIN LATERAL FLATTEN(input => a."cited_by") c
    JOIN "PATENTS_GOOGLE"."PATENTS_GOOGLE"."PUBLICATIONS" citing_publ
        ON c.value:"publication_number"::STRING = citing_publ."publication_number"
    WHERE p."family_id" IN (SELECT "family_id" FROM jan2015_families)
    GROUP BY p."family_id"
)
SELECT
    CAST(jf."family_id" AS STRING) AS "family_id",
    jf."earliest_publication_date",
    CAST(fpd."publication_numbers" AS STRING) AS "publication_numbers",
    CAST(fpd."country_codes" AS STRING) AS "country_codes",
    CAST(fcd."cpc_codes" AS STRING) AS "cpc_codes",
    CAST(fid."ipc_codes" AS STRING) AS "ipc_codes",
    CAST(fcdt."cited_families" AS STRING) AS "cited_families",
    CAST(fcitd."cited_by_families" AS STRING) AS "cited_by_families"
FROM
    jan2015_families jf
LEFT JOIN family_pub_data fpd ON jf."family_id" = fpd."family_id"
LEFT JOIN family_cpc_data fcd ON jf."family_id" = fcd."family_id"
LEFT JOIN family_ipc_data fid ON jf."family_id" = fid."family_id"
LEFT JOIN family_cited_data fcdt ON jf."family_id" = fcdt."family_id"
LEFT JOIN family_citing_data fcitd ON jf."family_id" = fcitd."family_id"
ORDER BY jf."family_id";