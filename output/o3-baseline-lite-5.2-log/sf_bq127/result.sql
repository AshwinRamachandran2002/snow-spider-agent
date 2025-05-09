WITH fam_earliest AS (   -- families whose first publication is in Jan‑2015
    SELECT 
        "family_id",
        MIN("publication_date") AS earliest_pub_date
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    GROUP BY "family_id"
    HAVING earliest_pub_date >= 20150101        -- 1‑Jan‑2015
       AND earliest_pub_date <  20150201        -- before 1‑Feb‑2015
), ---------------------------------------------------------------------------
pubs_in_fam AS (        -- every publication belonging to the above families
    SELECT  p.*
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    JOIN    fam_earliest f
           ON p."family_id" = f."family_id"
), ---------------------------------------------------------------------------
cpc_codes AS (          -- distinct CPC codes per family
    SELECT  DISTINCT 
            p."family_id",
            LOWER(f.value:"code"::string) AS code
    FROM    pubs_in_fam p,
            LATERAL FLATTEN(INPUT => p."cpc") f
    WHERE   f.value:"code" IS NOT NULL
), ---------------------------------------------------------------------------
ipc_codes AS (          -- distinct IPC codes per family
    SELECT  DISTINCT 
            p."family_id",
            LOWER(f.value:"code"::string) AS code
    FROM    pubs_in_fam p,
            LATERAL FLATTEN(INPUT => p."ipc") f
    WHERE   f.value:"code" IS NOT NULL
), ---------------------------------------------------------------------------
citations_out AS (      -- families that the target family CITES
    SELECT  DISTINCT 
            p."family_id"              AS src_family_id,
            q."family_id"              AS cited_family_id
    FROM    pubs_in_fam p,
            LATERAL FLATTEN(INPUT => p."citation") c
            JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS q
                 ON q."publication_number" = c.value:"publication_number"::string
    WHERE   q."family_id" IS NOT NULL
      AND   q."family_id" <> p."family_id"
), ---------------------------------------------------------------------------
citations_in AS (       -- families that CITE the target family
    SELECT  DISTINCT 
            q."family_id"              AS citing_family_id,
            p."family_id"              AS tgt_family_id
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS q,
            LATERAL FLATTEN(INPUT => q."citation") c
            JOIN pubs_in_fam p
                 ON p."publication_number" = c.value:"publication_number"::string
    WHERE   q."family_id" IS NOT NULL
      AND   q."family_id" <> p."family_id"
) ----------------------------------------------------------------------------
SELECT  f."family_id",
        f.earliest_pub_date                                                   AS earliest_publication_date,

        LISTAGG( DISTINCT p."publication_number", ',' )
              WITHIN GROUP (ORDER BY p."publication_number")                  AS publication_numbers,

        LISTAGG( DISTINCT p."country_code", ',' )
              WITHIN GROUP (ORDER BY p."country_code")                        AS country_codes,

        LISTAGG( DISTINCT cpc.code, ',' )
              WITHIN GROUP (ORDER BY cpc.code)                                AS cpc_codes,

        LISTAGG( DISTINCT ipc.code, ',' )
              WITHIN GROUP (ORDER BY ipc.code)                                AS ipc_codes,

        LISTAGG( DISTINCT co.cited_family_id, ',' )
              WITHIN GROUP (ORDER BY co.cited_family_id)                      AS cited_family_ids,

        LISTAGG( DISTINCT ci.citing_family_id, ',' )
              WITHIN GROUP (ORDER BY ci.citing_family_id)                     AS citing_family_ids
FROM    fam_earliest           f
LEFT JOIN pubs_in_fam          p  ON p."family_id" = f."family_id"
LEFT JOIN cpc_codes            cpc ON cpc."family_id" = f."family_id"
LEFT JOIN ipc_codes            ipc ON ipc."family_id" = f."family_id"
LEFT JOIN citations_out        co  ON co.src_family_id = f."family_id"
LEFT JOIN citations_in         ci  ON ci.tgt_family_id = f."family_id"
GROUP BY f."family_id", f.earliest_pub_date
ORDER BY f."family_id";