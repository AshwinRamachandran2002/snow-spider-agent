/*  Faster version – restrict all heavy work to the (small) set of
    families that have at least one publication in Jan-2015            */

----------------------------------- 1) families that appear in Jan-2015
WITH candidate_fams AS (
    SELECT DISTINCT "family_id"
    FROM   PATENTS_GOOGLE.PATENTS_GOOGLE."PUBLICATIONS"
    WHERE  "publication_date" BETWEEN 20150101 AND 20150131
),

----------------------------------- 2) earliest pub-date for those families
fam_first AS (
    SELECT  "family_id",
            MIN("publication_date") AS earliest_pub_date
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE."PUBLICATIONS"
    WHERE   "family_id" IN (SELECT "family_id" FROM candidate_fams)
    GROUP BY "family_id"
    HAVING  earliest_pub_date BETWEEN 20150101 AND 20150131
),

----------------------------------- 3) all publications within those families
pubs_in_fam AS (
    SELECT  p.*
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE."PUBLICATIONS" p
    JOIN    fam_first f
      ON    f."family_id" = p."family_id"
),

/*--------------- publication numbers & country codes -----------------------*/
pub_nums AS (
    SELECT  "family_id",
            LISTAGG(DISTINCT "publication_number", ',')
                    WITHIN GROUP (ORDER BY "publication_number") AS publication_numbers,
            LISTAGG(DISTINCT "country_code", ',')
                    WITHIN GROUP (ORDER BY "country_code")       AS country_codes
    FROM    pubs_in_fam
    GROUP BY "family_id"
),

/*--------------- CPC & IPC codes ------------------------------------------*/
cpc_codes AS (
    SELECT  p."family_id",
            LISTAGG(DISTINCT f.value:"code"::string, ',')
                    WITHIN GROUP (ORDER BY f.value:"code"::string) AS cpc_codes
    FROM    pubs_in_fam p,
            LATERAL FLATTEN(input => p."cpc") f
    GROUP BY p."family_id"
),
ipc_codes AS (
    SELECT  p."family_id",
            LISTAGG(DISTINCT f.value:"code"::string, ',')
                    WITHIN GROUP (ORDER BY f.value:"code"::string) AS ipc_codes
    FROM    pubs_in_fam p,
            LATERAL FLATTEN(input => p."ipc") f
    GROUP BY p."family_id"
),

/*--------------- families *cited by* this family --------------------------*/
cited_fams AS (
    SELECT DISTINCT
           pi."family_id"                     AS this_family,
           cp."family_id"                     AS cited_family
    FROM   pubs_in_fam pi,
           LATERAL FLATTEN(input => pi."citation") c
    JOIN   PATENTS_GOOGLE.PATENTS_GOOGLE."PUBLICATIONS" cp
           ON cp."publication_number" = c.value:"publication_number"::string
),
cited_agg AS (
    SELECT  this_family  AS family_id,
            LISTAGG(DISTINCT cited_family, ',')
                    WITHIN GROUP (ORDER BY cited_family)          AS cited_family_ids
    FROM    cited_fams
    GROUP BY this_family
),

/*--------------- families that *cite* this family -------------------------*/
pub_nums_small AS (          -- publication numbers inside our families
    SELECT DISTINCT "publication_number", "family_id"
    FROM   pubs_in_fam
),
citing_fams AS (
    SELECT DISTINCT
           pf."family_id"                    AS cited_family,   -- our family
           op."family_id"                    AS citing_family
    FROM   PATENTS_GOOGLE.PATENTS_GOOGLE."PUBLICATIONS" op,
           LATERAL FLATTEN(input => op."citation") c
    JOIN   pub_nums_small pf
           ON pf."publication_number" = c.value:"publication_number"::string
    WHERE  op."family_id" <> pf."family_id"
),
citing_agg AS (
    SELECT  cited_family  AS family_id,
            LISTAGG(DISTINCT citing_family, ',')
                    WITHIN GROUP (ORDER BY citing_family)        AS citing_family_ids
    FROM    citing_fams
    GROUP BY cited_family
)

----------------------------------- final result
SELECT  f."family_id",
        CAST(f.earliest_pub_date AS STRING)          AS earliest_publication_date,
        pn.publication_numbers,
        pn.country_codes,
        COALESCE(cc.cpc_codes , '')                  AS cpc_codes,
        COALESCE(ic.ipc_codes , '')                  AS ipc_codes,
        COALESCE(ci.citing_family_ids , '')          AS citing_family_ids,
        COALESCE(cd.cited_family_ids  , '')          AS cited_family_ids
FROM    fam_first     f
LEFT JOIN pub_nums    pn ON pn."family_id" = f."family_id"
LEFT JOIN cpc_codes   cc ON cc."family_id" = f."family_id"
LEFT JOIN ipc_codes   ic ON ic."family_id" = f."family_id"
LEFT JOIN citing_agg  ci ON ci.family_id   = f."family_id"
LEFT JOIN cited_agg   cd ON cd.family_id   = f."family_id"
ORDER BY f."family_id";