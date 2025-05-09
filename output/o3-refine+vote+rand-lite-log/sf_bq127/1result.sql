/* -----------------------------------------------------------
   Publication families whose very first publication
   appeared in JAN‑2015 together with aggregated data
-----------------------------------------------------------*/
WITH family_earliest AS (          /* families & their first pub‑date */
    SELECT  "family_id",
            MIN("publication_date") AS earliest_date
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    GROUP BY "family_id"
    HAVING  earliest_date BETWEEN 20150101 AND 20150131      -- January 2015
),

/* -----------------------------------------------------------
   All publications that belong to the target families
-----------------------------------------------------------*/
family_pubs AS (
    SELECT  p."family_id",
            p."publication_number",
            p."country_code"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS  p
            JOIN family_earliest f
              ON p."family_id" = f."family_id"
),

/* -----------------------------------------------------------
   CPC & IPC codes for those families
-----------------------------------------------------------*/
family_codes AS (
      /* CPC codes --------------------------------------------------- */
      SELECT  p."family_id",
              c.value:"code"::string AS code,
              'CPC' AS code_type
      FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS  p
              JOIN family_earliest f
                ON p."family_id" = f."family_id",
              LATERAL FLATTEN ( INPUT => p."cpc" ) c
      WHERE   c.value:"code" IS NOT NULL

      UNION ALL

      /* IPC codes --------------------------------------------------- */
      SELECT  p."family_id",
              i.value:"code"::string AS code,
              'IPC' AS code_type
      FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS  p
              JOIN family_earliest f
                ON p."family_id" = f."family_id",
              LATERAL FLATTEN ( INPUT => p."ipc" ) i
      WHERE   i.value:"code" IS NOT NULL
),

/* -----------------------------------------------------------
   Families that OUR families cite (outgoing references)
-----------------------------------------------------------*/
cited_families AS (
    SELECT  DISTINCT
            src."family_id"                    AS source_family_id,
            tgt."family_id"                    AS cited_family_id
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS  src
            JOIN family_pubs fp_src
              ON src."publication_number" = fp_src."publication_number",
            LATERAL FLATTEN ( INPUT => src."citation" ) cit
            JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS  tgt
              ON tgt."publication_number" = cit.value:"publication_number"::string
),

/* -----------------------------------------------------------
   Families that cite OUR families (incoming references)
   → use ABS_AND_EMB.cited_by so we only expand citations of
     the target publications, avoiding a full‑table scan
-----------------------------------------------------------*/
citing_families AS (
    SELECT  DISTINCT
            fp."family_id"                     AS cited_family_id,
            pub_citing."family_id"             AS citing_family_id
    FROM    family_pubs                       fp
            JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB emb
              ON emb."publication_number" = fp."publication_number"
            ,   LATERAL FLATTEN( INPUT => emb."cited_by" )  cb
            JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS pub_citing
              ON pub_citing."publication_number" = cb.value::string
)

/* -----------------------------------------------------------
   Final aggregation
-----------------------------------------------------------*/
SELECT
        fe."family_id"                                                   AS family_id,
        fe.earliest_date                                                 AS earliest_publication_date,

        /* publication numbers (comma‑separated, alphabetical) */
        ( SELECT LISTAGG( DISTINCT fp."publication_number", ',' )
                 WITHIN GROUP ( ORDER BY fp."publication_number" )
          FROM   family_pubs fp
          WHERE  fp."family_id" = fe."family_id"
        )                                                               AS publication_numbers,

        /* country codes */
        ( SELECT LISTAGG( DISTINCT fp."country_code", ',' )
                 WITHIN GROUP ( ORDER BY fp."country_code" )
          FROM   family_pubs fp
          WHERE  fp."family_id" = fe."family_id"
        )                                                               AS country_codes,

        /* CPC codes */
        ( SELECT LISTAGG( DISTINCT fc.code, ',' )
                 WITHIN GROUP ( ORDER BY fc.code )
          FROM   family_codes fc
          WHERE  fc."family_id" = fe."family_id"
            AND  fc.code_type  = 'CPC'
        )                                                               AS cpc_codes,

        /* IPC codes */
        ( SELECT LISTAGG( DISTINCT fc.code, ',' )
                 WITHIN GROUP ( ORDER BY fc.code )
          FROM   family_codes fc
          WHERE  fc."family_id" = fe."family_id"
            AND  fc.code_type  = 'IPC'
        )                                                               AS ipc_codes,

        /* families that CITE this family (incoming) */
        ( SELECT LISTAGG( DISTINCT cf.citing_family_id, ',' )
                 WITHIN GROUP ( ORDER BY cf.citing_family_id )
          FROM   citing_families cf
          WHERE  cf.cited_family_id = fe."family_id"
        )                                                               AS citing_family_ids,

        /* families that are CITED BY this family (outgoing) */
        ( SELECT LISTAGG( DISTINCT cd.cited_family_id, ',' )
                 WITHIN GROUP ( ORDER BY cd.cited_family_id )
          FROM   cited_families cd
          WHERE  cd.source_family_id = fe."family_id"
        )                                                               AS cited_family_ids

FROM    family_earliest  fe
ORDER BY fe."family_id";