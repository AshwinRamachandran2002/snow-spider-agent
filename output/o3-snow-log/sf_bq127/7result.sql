/*  Families whose very first publication appeared in January-2015 and,
    for those families, return earliest date, publication list,
    country codes, distinct CPC & IPC codes, and citing / cited families.          */

/* -------------------------------------------------------------------------- */
/* 1. Identify families whose first publication date is in Jan-2015           */
WITH family_first_pub AS (
    SELECT  "family_id",
            MIN("publication_date") AS earliest_date
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    GROUP BY "family_id"
    HAVING  earliest_date BETWEEN 20150101 AND 20150131      -- 1-Jan-2015 … 31-Jan-2015
),

/* -------------------------------------------------------------------------- */
/* 2. All publications belonging to those families                            */
family_pub_numbers AS (
    SELECT  p."family_id",
            p."publication_number",
            p."country_code"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    JOIN    family_first_pub f
           ON p."family_id" = f."family_id"
),

/* -------------------------------------------------------------------------- */
/* 3.  CPC  &  IPC codes                                                      */
codes_raw AS (

    /* ---- CPC codes ---- */
    SELECT  p."family_id",
            c.value:"code"::STRING        AS code,
            'CPC'                         AS code_type
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    JOIN    family_first_pub f
           ON p."family_id" = f."family_id",
           LATERAL FLATTEN(INPUT => p."cpc") c
    WHERE   c.value:"code" IS NOT NULL

    UNION ALL

    /* ---- IPC codes ---- */
    SELECT  p."family_id",
            i.value:"code"::STRING        AS code,
            'IPC'                         AS code_type
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    JOIN    family_first_pub f
           ON p."family_id" = f."family_id",
           LATERAL FLATTEN(INPUT => p."ipc") i
    WHERE   i.value:"code" IS NOT NULL
),

cpc_codes AS (
    SELECT  "family_id",
            LISTAGG(DISTINCT code, ',') WITHIN GROUP (ORDER BY code) AS cpc_codes
    FROM    codes_raw
    WHERE   code_type = 'CPC'
    GROUP BY "family_id"
),
ipc_codes AS (
    SELECT  "family_id",
            LISTAGG(DISTINCT code, ',') WITHIN GROUP (ORDER BY code) AS ipc_codes
    FROM    codes_raw
    WHERE   code_type = 'IPC'
    GROUP BY "family_id"
),

/* -------------------------------------------------------------------------- */
/* 4. Families that OUR family cites (out-going citations)                    */
cited_families AS (
    SELECT DISTINCT
           p."family_id"                       AS source_family_id,
           cited."family_id"                   AS cited_family_id
    FROM   PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    JOIN   family_first_pub f
          ON p."family_id" = f."family_id",
          LATERAL FLATTEN(INPUT => p."citation") fl,
          PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS cited
    WHERE  cited."publication_number" = fl.value:"publication_number"::STRING
      AND  cited."family_id" <> p."family_id"
),

cited_agg AS (
    SELECT  source_family_id AS family_id,
            LISTAGG(DISTINCT cited_family_id, ',') 
                    WITHIN GROUP (ORDER BY cited_family_id) AS cited_family_ids
    FROM    cited_families
    GROUP BY source_family_id
),

/* -------------------------------------------------------------------------- */
/* 5. Families that cite OUR family (in-coming citations)                     */
/*    To avoid unsupported JOIN-with-LATERAL syntax, first flatten citations,
      then join to our publication list                                       */
flattened_citations AS (
    SELECT  citing."family_id",
            fl.value:"publication_number"::STRING AS cited_pub_number
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS citing,
            LATERAL FLATTEN(INPUT => citing."citation") fl
),

citing_families AS (
    SELECT DISTINCT
           fc."family_id"        AS citing_family_id,
           fp."family_id"        AS target_family_id
    FROM   flattened_citations  fc
    JOIN   family_pub_numbers   fp
           ON fc.cited_pub_number = fp."publication_number"
    WHERE  fc."family_id" <> fp."family_id"
),

citing_agg AS (
    SELECT  target_family_id AS family_id,
            LISTAGG(DISTINCT citing_family_id, ',')
                    WITHIN GROUP (ORDER BY citing_family_id) AS citing_family_ids
    FROM    citing_families
    GROUP BY target_family_id
),

/* -------------------------------------------------------------------------- */
/* 6. Publication numbers & country codes per family                          */
pub_lists AS (
    SELECT  "family_id",
            LISTAGG(DISTINCT "publication_number", ',')
                    WITHIN GROUP (ORDER BY "publication_number") AS publication_numbers,
            LISTAGG(DISTINCT "country_code", ',')
                    WITHIN GROUP (ORDER BY "country_code")       AS country_codes
    FROM    family_pub_numbers
    GROUP BY "family_id"
)

/* -------------------------------------------------------------------------- */
/* 7. Final result                                                            */
SELECT  f."family_id",
        f.earliest_date,
        p.publication_numbers,
        p.country_codes,
        cpc.cpc_codes,
        ipc.ipc_codes,
        cf.cited_family_ids,
        cg.citing_family_ids
FROM    family_first_pub  f
LEFT JOIN pub_lists  p  ON p."family_id" = f."family_id"
LEFT JOIN cpc_codes  cpc ON cpc."family_id" = f."family_id"
LEFT JOIN ipc_codes  ipc ON ipc."family_id" = f."family_id"
LEFT JOIN cited_agg  cf  ON cf.family_id   = f."family_id"
LEFT JOIN citing_agg cg  ON cg.family_id   = f."family_id"
ORDER BY f."family_id";