/* -----------------------------------------------------------
   Families whose very first (earliest) publication appeared
   between 01-Jan-2015 and 31-Jan-2015 ­– together with
   • earliest publication date
   • all publication numbers in the family
   • all country codes in the family
   • all CPC codes in the family
   • all IPC codes in the family
   • families that cite this family            (families_citing)
   • families that are cited by this family    (families_cited)
   Every list is returned as comma-separated values, sorted
   alphabetically / numerically.
----------------------------------------------------------- */
WITH
/* 1.  Families whose first publication is in Jan-2015 */
family_earliest AS (
    SELECT
        "family_id",
        MIN("publication_date") AS earliest_date
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    GROUP BY "family_id"
    HAVING MIN("publication_date") BETWEEN 20150101 AND 20150131
),

/* 2.  All publications that belong to those families */
target_pubs AS (
    SELECT  p.*
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    JOIN    family_earliest f
           ON f."family_id" = p."family_id"
),

/* 3.  Aggregated publication numbers & country codes */
pub_agg AS (
    SELECT
        "family_id",
        LISTAGG(DISTINCT "publication_number", ',')
            WITHIN GROUP (ORDER BY "publication_number")   AS publication_numbers,
        LISTAGG(DISTINCT "country_code", ',')
            WITHIN GROUP (ORDER BY "country_code")         AS country_codes
    FROM target_pubs
    GROUP BY "family_id"
),

/* 4.  CPC aggregation */
cpc_agg AS (
    SELECT
        t."family_id",
        LISTAGG(DISTINCT c.value:"code"::STRING, ',')
            WITHIN GROUP (ORDER BY c.value:"code"::STRING) AS cpc_codes
    FROM target_pubs          t,
         LATERAL FLATTEN (INPUT => t."cpc") c
    WHERE c.value:"code" IS NOT NULL
    GROUP BY t."family_id"
),

/* 5.  IPC aggregation */
ipc_agg AS (
    SELECT
        t."family_id",
        LISTAGG(DISTINCT i.value:"code"::STRING, ',')
            WITHIN GROUP (ORDER BY i.value:"code"::STRING) AS ipc_codes
    FROM target_pubs          t,
         LATERAL FLATTEN (INPUT => t."ipc") i
    WHERE i.value:"code" IS NOT NULL
    GROUP BY t."family_id"
),

/* 6.  Families that THIS family cites (outgoing citations) */
families_cited AS (
    SELECT DISTINCT
        tp."family_id"                 AS target_family,
        cited_pub."family_id"          AS cited_family
    FROM target_pubs tp,
         LATERAL FLATTEN (INPUT => tp."citation") cit
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS  cited_pub
         ON cited_pub."publication_number" = cit.value:"publication_number"::STRING
    WHERE cit.value:"publication_number" IS NOT NULL
),
cited_agg AS (
    SELECT
        target_family,
        LISTAGG(DISTINCT cited_family, ',')
            WITHIN GROUP (ORDER BY cited_family) AS families_cited
    FROM families_cited
    GROUP BY target_family
),

/* 7.  Families that cite THIS family (incoming citations) */
families_citing AS (
    SELECT DISTINCT
        cp."family_id"                 AS citing_family,
        tp."family_id"                 AS target_family
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS cp,
         LATERAL FLATTEN (INPUT => cp."citation") cit
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS tp
         ON tp."publication_number" = cit.value:"publication_number"::STRING
    JOIN family_earliest fe
         ON fe."family_id" = tp."family_id"
    WHERE cit.value:"publication_number" IS NOT NULL
),
citing_agg AS (
    SELECT
        target_family,
        LISTAGG(DISTINCT citing_family, ',')
            WITHIN GROUP (ORDER BY citing_family) AS families_citing
    FROM families_citing
    GROUP BY target_family
)

/* 8.  Final assembly ------------------------------------------------------*/
SELECT
    fe."family_id",
    fe.earliest_date                                AS earliest_publication_date,
    pa.publication_numbers,
    pa.country_codes,
    COALESCE(cpc.cpc_codes,   '')                   AS cpc_codes,
    COALESCE(ipc.ipc_codes,   '')                   AS ipc_codes,
    COALESCE(citing.families_citing, '')            AS families_citing,
    COALESCE(cited.families_cited,  '')             AS families_cited
FROM family_earliest  fe
LEFT JOIN pub_agg   pa   ON pa."family_id"    = fe."family_id"
LEFT JOIN cpc_agg   cpc  ON cpc."family_id"   = fe."family_id"
LEFT JOIN ipc_agg   ipc  ON ipc."family_id"   = fe."family_id"
LEFT JOIN citing_agg citing ON citing.target_family = fe."family_id"
LEFT JOIN cited_agg  cited  ON cited.target_family  = fe."family_id"
ORDER BY fe."family_id";