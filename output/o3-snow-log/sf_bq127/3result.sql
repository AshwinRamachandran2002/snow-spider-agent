/*  Families whose earliest publication appeared in Jan-2015 and required roll-ups                    */
WITH target_families AS (               -- families whose first publication is in 2015-01
    SELECT  "family_id",
            MIN("publication_date") AS earliest_pub_date
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    GROUP BY "family_id"
    HAVING  MIN("publication_date") BETWEEN 20150101 AND 20150131
),                                                                  
family_pubs AS (                        -- every publication in those families
    SELECT  p.*
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
            JOIN target_families tf ON tf."family_id" = p."family_id"
),                                                                   
/* ---------- CPC & IPC codes ------------------------------------ */                                  
pub_cpc AS (                            -- all CPC codes for each family
    SELECT  fp."family_id",
            TRIM(fc.value:"code"::STRING) AS code
    FROM    family_pubs fp
    CROSS JOIN LATERAL FLATTEN(INPUT => fp."cpc") fc
    WHERE   fc.value:"code" IS NOT NULL
),                                                                   
pub_ipc AS (                            -- all IPC codes for each family
    SELECT  fp."family_id",
            TRIM(fi.value:"code"::STRING) AS code
    FROM    family_pubs fp
    CROSS JOIN LATERAL FLATTEN(INPUT => fp."ipc") fi
    WHERE   fi.value:"code" IS NOT NULL
),                                                                   
/* ---------- families that the target families CITE ------------- */                                   
cited_families AS (
    SELECT  DISTINCT fp."family_id"            AS source_family,
            pub2."family_id"                   AS cited_family
    FROM    family_pubs fp
    CROSS JOIN LATERAL FLATTEN(INPUT => fp."citation") c
    LEFT  JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS pub2
           ON pub2."publication_number" = c.value:"publication_number"::STRING
    WHERE   pub2."family_id" IS NOT NULL
      AND   pub2."family_id" <> fp."family_id"
),                                                                   
/* ---------- families that CITE the target families ------------- */                                   
mynumbers AS (                          -- every pub-number in the target families
    SELECT  "family_id", "publication_number"
    FROM    family_pubs
),                                                                   
citing_families AS (
    SELECT  DISTINCT tf."family_id"            AS target_family,
            p2."family_id"                     AS citing_family
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p2
    CROSS JOIN LATERAL FLATTEN(INPUT => p2."citation") c
    JOIN    mynumbers m
           ON c.value:"publication_number"::STRING = m."publication_number"
    JOIN    target_families tf
           ON tf."family_id" = m."family_id"
    WHERE   p2."family_id" <> tf."family_id"
)                                                                    
/* ---------- final aggregation ---------------------------------- */
SELECT  tf."family_id"                                                   AS "FAMILY_ID",
        TO_VARCHAR(tf.earliest_pub_date)                                 AS "EARLIEST_PUBLICATION_DATE",
        LISTAGG(DISTINCT fp."publication_number", ', ')
            WITHIN GROUP (ORDER BY fp."publication_number")              AS "PUBLICATION_NUMBERS",
        LISTAGG(DISTINCT fp."country_code", ', ')
            WITHIN GROUP (ORDER BY fp."country_code")                    AS "COUNTRY_CODES",
        LISTAGG(DISTINCT pc.code, ', ')
            WITHIN GROUP (ORDER BY pc.code)                              AS "CPC_CODES",
        LISTAGG(DISTINCT pi.code, ', ')
            WITHIN GROUP (ORDER BY pi.code)                              AS "IPC_CODES",
        LISTAGG(DISTINCT cf.cited_family, ', ')
            WITHIN GROUP (ORDER BY cf.cited_family)                      AS "CITED_FAMILIES",
        LISTAGG(DISTINCT cf2.citing_family, ', ')
            WITHIN GROUP (ORDER BY cf2.citing_family)                    AS "CITING_FAMILIES"
FROM        target_families      tf
LEFT JOIN   family_pubs         fp  ON fp."family_id"   = tf."family_id"
LEFT JOIN   pub_cpc             pc  ON pc."family_id"   = tf."family_id"
LEFT JOIN   pub_ipc             pi  ON pi."family_id"   = tf."family_id"
LEFT JOIN   cited_families      cf  ON cf.source_family = tf."family_id"
LEFT JOIN   citing_families     cf2 ON cf2.target_family= tf."family_id"
GROUP BY    tf."family_id", tf.earliest_pub_date
ORDER BY    tf."family_id";