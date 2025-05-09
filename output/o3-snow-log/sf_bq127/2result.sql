/* -----------------------------------------------------------
   Families whose first publication appeared in January-2015
   -----------------------------------------------------------*/
WITH earliest_pub AS (          /* 1. families + their very first publication date           */
    SELECT
        "family_id",
        MIN("publication_date")           AS earliest_date
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    GROUP BY "family_id"
    HAVING earliest_date BETWEEN 20150101 AND 20150131           -- January-2015 only
),                                                                
/* 2. every publication that belongs to those families           */
family_pubs AS (
    SELECT
        p."family_id",
        p."publication_number",
        p."country_code",
        p."cpc",
        p."ipc",
        p."citation"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    JOIN earliest_pub e
          ON e."family_id" = p."family_id"
),
/* 3. helper: publication numbers of the target families         */
fam_pub_nums AS (
    SELECT DISTINCT
        "family_id",
        "publication_number"
    FROM family_pubs
),
/* 4. CPC / IPC codes                                            */
cpc_codes AS (
    SELECT DISTINCT
        fp."family_id",
        f.value:"code"::string AS code
    FROM family_pubs fp,
         LATERAL FLATTEN (input => fp."cpc") f
    WHERE f.value:"code" IS NOT NULL
),
ipc_codes AS (
    SELECT DISTINCT
        fp."family_id",
        f.value:"code"::string AS code
    FROM family_pubs fp,
         LATERAL FLATTEN (input => fp."ipc") f
    WHERE f.value:"code" IS NOT NULL
),
/* 5. families THAT ARE CITED by our families                    */
cited_families AS (
    SELECT
        fp."family_id",
        LISTAGG(DISTINCT cited."family_id", ', ')
            WITHIN GROUP (ORDER BY cited."family_id")  AS cited_family_ids
    FROM family_pubs fp,
         LATERAL FLATTEN (input => fp."citation") c,
         PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS  cited
    WHERE cited."publication_number" = c.value:"publication_number"::string
    GROUP BY fp."family_id"
),
/* 6. families THAT CITE our families                            */
citing_families AS (
    SELECT
        fpn."family_id",
        LISTAGG(DISTINCT other."family_id", ', ')
            WITHIN GROUP (ORDER BY other."family_id") AS citing_family_ids
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS other,
         LATERAL FLATTEN (input => other."citation") c,
         fam_pub_nums              fpn
    WHERE fpn."publication_number" = c.value:"publication_number"::string
      AND other."family_id"       <> fpn."family_id"        -- exclude self-citations
    GROUP BY fpn."family_id"
)
/* -------------------------------------------------------------
   7.  Final assembly                                           
   -------------------------------------------------------------*/
SELECT
    e."family_id",
    e.earliest_date                                       AS "earliest_publication_date",
    /* publication numbers in the family */
    ( SELECT LISTAGG(DISTINCT "publication_number", ', ')
              WITHIN GROUP (ORDER BY "publication_number")
        FROM family_pubs
       WHERE "family_id" = e."family_id")                AS "publication_numbers",
    /* country codes present in the family */
    ( SELECT LISTAGG(DISTINCT "country_code", ', ')
              WITHIN GROUP (ORDER BY "country_code")
        FROM family_pubs
       WHERE "family_id" = e."family_id")                AS "country_codes",
    /* CPC codes */
    ( SELECT LISTAGG(DISTINCT code, ', ')
              WITHIN GROUP (ORDER BY code)
        FROM cpc_codes
       WHERE "family_id" = e."family_id")                AS "cpc_codes",
    /* IPC codes */
    ( SELECT LISTAGG(DISTINCT code, ', ')
              WITHIN GROUP (ORDER BY code)
        FROM ipc_codes
       WHERE "family_id" = e."family_id")                AS "ipc_codes",
    COALESCE(cf.citing_family_ids, '')                   AS "families_citing_this_family",
    COALESCE(cd.cited_family_ids , '')                   AS "families_cited_by_this_family"
FROM earliest_pub          e
LEFT JOIN citing_families  cf ON cf."family_id" = e."family_id"
LEFT JOIN cited_families   cd ON cd."family_id" = e."family_id"
ORDER BY e."family_id";