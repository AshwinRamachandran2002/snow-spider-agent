/* -------------------------------------------------------------------------
   1)   Identify simple-patent-families whose VERY FIRST publication
        occurred  in January-2015 ( any country, any kind-code ).
---------------------------------------------------------------------------*/
WITH jan15_fam AS (               ------------------------------------------------
    SELECT  "family_id"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    QUALIFY ROW_NUMBER() OVER (PARTITION BY "family_id"
                               ORDER BY "publication_date") = 1
            AND "publication_date" BETWEEN 20150101 AND 20150131
)
/* -------------------------------------------------------------------------
   2)   All publications that belong to those families  (kept small by
        filtering on the family_id list obtained above).  These rows
        will be reused many times – hence materialise once in a CTE.
---------------------------------------------------------------------------*/
, fam_pubs AS (                   -- only a few-tens-of-thousands rows
    SELECT  "family_id",
            "publication_number",
            "country_code",
            "publication_date",
            "cpc",
            "ipc",
            "citation"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    WHERE   "family_id" IN (SELECT "family_id" FROM jan15_fam)
)
/* -------------------------------------------------------------------------
   3)   Earliest publication date  (per family)  ---------------------------
---------------------------------------------------------------------------*/
, earliest_pub AS (
    SELECT  "family_id",
            MIN("publication_date") AS earliest_pub_date
    FROM    fam_pubs
    GROUP BY "family_id"
)
/* -------------------------------------------------------------------------
   4)   CPC & IPC code sets  (per family, already limited to our pubs) -----
---------------------------------------------------------------------------*/
, fam_cpc AS (
    SELECT  fp."family_id",
            LISTAGG(DISTINCT c.value:"code"::STRING , ',')
                 WITHIN GROUP (ORDER BY c.value:"code"::STRING)  AS cpc_codes
    FROM    fam_pubs fp,
            LATERAL FLATTEN(input => fp."cpc") c
    GROUP BY fp."family_id"
)
, fam_ipc AS (
    SELECT  fp."family_id",
            LISTAGG(DISTINCT i.value:"code"::STRING , ',')
                 WITHIN GROUP (ORDER BY i.value:"code"::STRING)  AS ipc_codes
    FROM    fam_pubs fp,
            LATERAL FLATTEN(input => fp."ipc") i
    GROUP BY fp."family_id"
)
/* -------------------------------------------------------------------------
   5)   Families THAT our Jan-2015 families CITE  (outgoing citations) -----
---------------------------------------------------------------------------*/
, out_cites AS (
    SELECT  DISTINCT
            src."family_id"                       AS source_family,
            tgt."family_id"                       AS cited_family
    FROM    fam_pubs  src,
            LATERAL FLATTEN(input => src."citation") cit
            JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS  tgt
                 ON tgt."publication_number" = cit.value:"publication_number"::STRING
    WHERE   cit.value:"publication_number" IS NOT NULL
)
/* -------------------------------------------------------------------------
   6)   Families that CITE ANY publication of our Jan-2015 families
        (incoming citations).   First prepare a small list of all pub-nums
        belonging to the Jan-2015 families so the subsequent join/filter
        is cheap even though we have to FLATTEN the global table once.
---------------------------------------------------------------------------*/
, jan15_pub_nums AS (
    SELECT DISTINCT "publication_number"
    FROM   fam_pubs
)
, in_cites AS (
    SELECT  DISTINCT
            tgt."family_id"                       AS target_family,
            src."family_id"                       AS citing_family
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS  src,
            LATERAL FLATTEN(input => src."citation") cit
            JOIN jan15_pub_nums  j
                 ON j."publication_number" = cit.value:"publication_number"::STRING
            JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS  tgt
                 ON tgt."publication_number" = j."publication_number"
)
/* -------------------------------------------------------------------------
   7)   Final assembly  -----------------------------------------------------
---------------------------------------------------------------------------*/
SELECT
    b."family_id",
    e.earliest_pub_date,
    /*  publication numbers & country codes --------------------------------*/
    LISTAGG(DISTINCT fp."publication_number", ',')
           WITHIN GROUP (ORDER BY fp."publication_number")     AS publication_numbers,
    LISTAGG(DISTINCT fp."country_code", ',')
           WITHIN GROUP (ORDER BY fp."country_code")           AS country_codes,
    /*  CPC & IPC ----------------------------------------------------------*/
    c.cpc_codes,
    i.ipc_codes,
    /*  citing / cited-by family lists  ------------------------------------*/
    ( SELECT LISTAGG(DISTINCT inc.citing_family , ',')
              WITHIN GROUP (ORDER BY inc.citing_family)
      FROM   in_cites inc
      WHERE  inc.target_family = b."family_id"
    )  AS cited_by_family_ids,
    ( SELECT LISTAGG(DISTINCT oc.cited_family , ',')
              WITHIN GROUP (ORDER BY oc.cited_family)
      FROM   out_cites oc
      WHERE  oc.source_family = b."family_id"
    )  AS cites_family_ids
FROM      jan15_fam                 b
JOIN      earliest_pub              e  ON e."family_id" = b."family_id"
JOIN      fam_pubs                  fp ON fp."family_id" = b."family_id"
LEFT JOIN fam_cpc                   c  ON c."family_id"  = b."family_id"
LEFT JOIN fam_ipc                   i  ON i."family_id"  = b."family_id"
GROUP BY  b."family_id",
          e.earliest_pub_date,
          c.cpc_codes,
          i.ipc_codes
ORDER BY  b."family_id";