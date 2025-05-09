WITH family_earliest AS (       /* families whose first publication is in Jan‑2015 */
    SELECT  "family_id",
            MIN("publication_date") AS earliest_pub_date
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    GROUP BY "family_id"
    HAVING  earliest_pub_date BETWEEN 20150101 AND 20150131
),

/* ----------------------------------------------------------- */
/*  basic data for every selected family                       */
family_pubs AS (
    SELECT  p."family_id",
            p."publication_number",
            p."country_code"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    JOIN    family_earliest fe
           ON p."family_id" = fe."family_id"
),

/* ----------------------------------------------------------- */
/*  CPC and IPC codes                                          */
family_cpc AS (
    SELECT  DISTINCT p."family_id",
            f.value:"code"::string AS code
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    JOIN    family_earliest fe
           ON p."family_id" = fe."family_id"
    CROSS JOIN LATERAL FLATTEN(input => p."cpc") f
    WHERE   f.value:"code" IS NOT NULL
),

family_ipc AS (
    SELECT  DISTINCT p."family_id",
            f.value:"code"::string AS code
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    JOIN    family_earliest fe
           ON p."family_id" = fe."family_id"
    CROSS JOIN LATERAL FLATTEN(input => p."ipc") f
    WHERE   f.value:"code" IS NOT NULL
),

/* ----------------------------------------------------------- */
/*  outgoing citations (our family  ->  other families)        */
cited_families AS (
    SELECT  DISTINCT fe."family_id"          AS source_family,
            p2."family_id"                  AS cited_family
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p1
    JOIN    family_earliest fe
           ON p1."family_id" = fe."family_id"
    CROSS JOIN LATERAL FLATTEN(input => p1."citation") c
    JOIN    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p2
           ON p2."publication_number" = c.value:"publication_number"::string
    WHERE   p2."family_id" IS NOT NULL
),

/* ----------------------------------------------------------- */
/*  incoming citations (other families  ->  our family)        */
citing_families AS (
    SELECT  DISTINCT p2."family_id"          AS citing_family,
            fe."family_id"                  AS target_family
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p2
    CROSS JOIN LATERAL FLATTEN(input => p2."citation") c
    JOIN    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p1
           ON p1."publication_number" = c.value:"publication_number"::string
    JOIN    family_earliest fe
           ON p1."family_id" = fe."family_id"
    WHERE   p2."family_id" <> fe."family_id"
)

/* ----------------------------------------------------------- */
/*  final aggregation                                          */
SELECT  fe."family_id"                                                        AS "FAMILY_ID",
        fe.earliest_pub_date                                                  AS "EARLIEST_PUBLICATION_DATE",
        LISTAGG(DISTINCT fp."publication_number", ', ')
            WITHIN GROUP (ORDER BY fp."publication_number")                   AS "PUBLICATION_NUMBERS",
        LISTAGG(DISTINCT fp."country_code", ', ')
            WITHIN GROUP (ORDER BY fp."country_code")                         AS "COUNTRY_CODES",
        LISTAGG(DISTINCT fc.code, ', ')
            WITHIN GROUP (ORDER BY fc.code)                                   AS "CPC_CODES",
        LISTAGG(DISTINCT fi.code, ', ')
            WITHIN GROUP (ORDER BY fi.code)                                   AS "IPC_CODES",
        LISTAGG(DISTINCT cf.cited_family, ', ')
            WITHIN GROUP (ORDER BY cf.cited_family)                           AS "FAMILIES_CITED",
        LISTAGG(DISTINCT ct.citing_family, ', ')
            WITHIN GROUP (ORDER BY ct.citing_family)                          AS "FAMILIES_CITING"
FROM    family_earliest   fe
LEFT JOIN family_pubs      fp  ON fp."family_id" = fe."family_id"
LEFT JOIN family_cpc       fc  ON fc."family_id" = fe."family_id"
LEFT JOIN family_ipc       fi  ON fi."family_id" = fe."family_id"
LEFT JOIN cited_families   cf  ON cf.source_family = fe."family_id"
LEFT JOIN citing_families  ct  ON ct.target_family = fe."family_id"
GROUP BY fe."family_id", fe.earliest_pub_date
ORDER BY fe."family_id";