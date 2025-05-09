/*  Aggregated view of all patent families whose very first
    publication occurred in January-2015                                          */

-------------------------------------------------------------------------------
-- 1)  Identify the target families and all of their publications
-------------------------------------------------------------------------------
WITH first_pub AS (          -- families first seen in Jan-2015
    SELECT  "family_id",
            MIN("publication_date") AS first_date
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    GROUP BY "family_id"
    HAVING  MIN("publication_date") BETWEEN 20150101 AND 20150131
),

target_pubs AS (             -- every publication that belongs to those families
    SELECT  p."family_id",
            p."publication_number",
            p."country_code",
            p."cpc",
            p."ipc",
            p."citation"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    JOIN    first_pub f  ON f."family_id" = p."family_id"
),

-------------------------------------------------------------------------------
-- 2)  Build all required aggregates on the much smaller “target_pubs” set
-------------------------------------------------------------------------------
pub_agg AS (                 -- publication numbers & country codes
    SELECT  "family_id",
            LISTAGG(DISTINCT "publication_number", ', ')
                   WITHIN GROUP (ORDER BY "publication_number")  AS pub_numbers,
            LISTAGG(DISTINCT "country_code", ', ')
                   WITHIN GROUP (ORDER BY "country_code")        AS country_codes
    FROM    target_pubs
    GROUP BY "family_id"
),

cpc_agg AS (                 -- CPC codes
    SELECT  tp."family_id",
            LISTAGG(DISTINCT c.value:"code"::STRING, ', ')
                   WITHIN GROUP (ORDER BY c.value:"code"::STRING) AS cpc_codes
    FROM    target_pubs tp,
            LATERAL FLATTEN(input => tp."cpc") c
    GROUP BY tp."family_id"
),

ipc_agg AS (                 -- IPC codes
    SELECT  tp."family_id",
            LISTAGG(DISTINCT i.value:"code"::STRING, ', ')
                   WITHIN GROUP (ORDER BY i.value:"code"::STRING) AS ipc_codes
    FROM    target_pubs tp,
            LATERAL FLATTEN(input => tp."ipc") i
    GROUP BY tp."family_id"
),

-------------------------------------------------------------------------------
-- 3)  Outgoing citations  (target → others)
-------------------------------------------------------------------------------
out_cited AS (
    SELECT  tp."family_id"                                       AS source_family,
            LISTAGG(DISTINCT tgt."family_id", ', ')
                   WITHIN GROUP (ORDER BY tgt."family_id")       AS cited_family_ids
    FROM    target_pubs           tp,
            LATERAL FLATTEN(input => tp."citation") c
    JOIN    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS  tgt
           ON tgt."publication_number" = c.value:"publication_number"::STRING
    GROUP BY tp."family_id"
),

-------------------------------------------------------------------------------
-- 4)  Incoming citations  (others → target)
--     • build a small look-up table of all publication numbers that belong
--       to the target families, then match citations from ANY publication
-------------------------------------------------------------------------------
target_pub_numbers AS (      -- quick look-up table for join
    SELECT DISTINCT "publication_number", "family_id"
    FROM   target_pubs
),

incoming_raw AS (            -- who cites any of those publication numbers
    SELECT  DISTINCT
            src."family_id"  AS citing_family,
            tpn."family_id"  AS target_family
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS  src,
            LATERAL FLATTEN(input => src."citation")    c
    JOIN    target_pub_numbers  tpn
          ON tpn."publication_number" = c.value:"publication_number"::STRING
),

incoming_citing AS (         -- aggregate list per target family
    SELECT  target_family,
            LISTAGG(DISTINCT citing_family, ', ')
                   WITHIN GROUP (ORDER BY citing_family)  AS citing_family_ids
    FROM    incoming_raw
    GROUP BY target_family
)

-------------------------------------------------------------------------------
-- 5)  Final report
-------------------------------------------------------------------------------
SELECT  fp."family_id",
        fp.first_date,
        pa.pub_numbers,
        pa.country_codes,
        COALESCE(ca.cpc_codes , '')           AS cpc_codes,
        COALESCE(ia.ipc_codes , '')           AS ipc_codes,
        COALESCE(oc.cited_family_ids , '')    AS cited_family_ids,
        COALESCE(ic.citing_family_ids, '')    AS citing_family_ids
FROM    first_pub         fp
LEFT JOIN pub_agg         pa ON pa."family_id"      = fp."family_id"
LEFT JOIN cpc_agg         ca ON ca."family_id"      = fp."family_id"
LEFT JOIN ipc_agg         ia ON ia."family_id"      = fp."family_id"
LEFT JOIN out_cited       oc ON oc.source_family    = fp."family_id"
LEFT JOIN incoming_citing ic ON ic.target_family    = fp."family_id"
ORDER BY fp.first_date, fp."family_id";