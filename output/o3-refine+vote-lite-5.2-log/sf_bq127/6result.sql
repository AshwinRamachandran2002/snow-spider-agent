/* -----------------------------------------------------------------
   Families whose very first publication was released in JAN‑2015,
   together with
        • earliest publication date
        • publication numbers  (distinct, alphabetical)
        • country codes        (distinct, alphabetical)
        • CPC and IPC codes    (distinct, alphabetical)
        • families they cite   (outgoing)
        • families that cite them (incoming)
   ----------------------------------------------------------------*/
WITH
/* ---------------------------------------------------------------
   1)  keep only families that HAVE a January‑2015 publication
-----------------------------------------------------------------*/
jan15_fams AS (        -- small list, used to limit later scans
    SELECT DISTINCT "family_id"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    WHERE "publication_date" BETWEEN 20150101 AND 20150131
),
/* ---------------------------------------------------------------
   2)  true earliest date for those families
-----------------------------------------------------------------*/
earliest_per_family AS (
    SELECT "family_id",
           MIN("publication_date") AS earliest_date
    FROM   PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    WHERE  "family_id" IN (SELECT "family_id" FROM jan15_fams)
    GROUP  BY "family_id"
),
target_families AS (
    SELECT  "family_id", earliest_date
    FROM    earliest_per_family
    WHERE   earliest_date BETWEEN 20150101 AND 20150131
),

/* ---------------------------------------------------------------
   3)  all publications that belong to the target families
-----------------------------------------------------------------*/
family_pubs AS (
    SELECT p."family_id",
           p."publication_number",
           p."country_code",
           p."cpc",
           p."ipc",
           p."citation"
    FROM   PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    JOIN   target_families tf  ON p."family_id" = tf."family_id"
),

/* ---------------------------------------------------------------
   4)  publication numbers + country codes
-----------------------------------------------------------------*/
pub_agg AS (
    SELECT "family_id",
           LISTAGG(DISTINCT "publication_number", ', ')
               WITHIN GROUP (ORDER BY "publication_number") AS publication_numbers,
           LISTAGG(DISTINCT "country_code", ', ')
               WITHIN GROUP (ORDER BY "country_code")       AS country_codes
    FROM   family_pubs
    GROUP  BY "family_id"
),

/* ---------------------------------------------------------------
   5)  CPC  (flatten once, aggregate)
-----------------------------------------------------------------*/
cpc_flat AS (
    SELECT fp."family_id",
           f.value:"code"::string AS code
    FROM   family_pubs fp,
           LATERAL FLATTEN(INPUT => fp."cpc") f
    WHERE  f.value:"code" IS NOT NULL
),
cpc_agg AS (
    SELECT "family_id",
           LISTAGG(DISTINCT code, ', ')
               WITHIN GROUP (ORDER BY code)                AS cpc_codes
    FROM   cpc_flat
    GROUP  BY "family_id"
),

/* ---------------------------------------------------------------
   6)  IPC
-----------------------------------------------------------------*/
ipc_flat AS (
    SELECT fp."family_id",
           f.value:"code"::string AS code
    FROM   family_pubs fp,
           LATERAL FLATTEN(INPUT => fp."ipc") f
    WHERE  f.value:"code" IS NOT NULL
),
ipc_agg AS (
    SELECT "family_id",
           LISTAGG(DISTINCT code, ', ')
               WITHIN GROUP (ORDER BY code)                AS ipc_codes
    FROM   ipc_flat
    GROUP  BY "family_id"
),

/* ---------------------------------------------------------------
   7)  OUTGOING ‑ families that this family cites
-----------------------------------------------------------------*/
out_pubnums AS (       -- distinct cited publication numbers
    SELECT DISTINCT fp."family_id",
           c.value:"publication_number"::string AS cited_pub
    FROM   family_pubs fp,
           LATERAL FLATTEN(INPUT => fp."citation") c
    WHERE  c.value:"publication_number" IS NOT NULL
),
cited_fams AS (        -- map cited publication -> its family
    SELECT op."family_id"      AS src_family,
           p2."family_id"      AS cited_family
    FROM   out_pubnums  op
    JOIN   PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p2
           ON p2."publication_number" = op.cited_pub
    WHERE  p2."family_id" IS NOT NULL
      AND  p2."family_id" <> op."family_id"
),
cited_fams_agg AS (
    SELECT src_family AS family_id,
           LISTAGG(DISTINCT cited_family, ', ')
               WITHIN GROUP (ORDER BY cited_family)        AS families_cited
    FROM   cited_fams
    GROUP  BY src_family
),

/* ---------------------------------------------------------------
   8)  INCOMING ‑ families that cite any publication of this family
       (use much smaller ABS_AND_EMB.cited_by list instead of
        scanning all PUBLICATIONS.citation)
-----------------------------------------------------------------*/
target_pubnums AS (
    SELECT DISTINCT "publication_number", "family_id"
    FROM   family_pubs
),
incoming_pairs AS (
    SELECT DISTINCT tp."family_id"              AS tgt_family,
                    pub2."family_id"            AS citing_family
    FROM   target_pubnums tp

    JOIN   PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB ae
           ON ae."publication_number" = tp."publication_number"

         , LATERAL FLATTEN(INPUT => ae."cited_by") cb

    JOIN   PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS pub2
           ON pub2."publication_number" = cb.value::string

    WHERE  pub2."family_id" <> tp."family_id"
),
incoming_agg AS (
    SELECT tgt_family AS family_id,
           LISTAGG(DISTINCT citing_family, ', ')
               WITHIN GROUP (ORDER BY citing_family)       AS families_cited_by
    FROM   incoming_pairs
    GROUP  BY tgt_family
)

/* ---------------------------------------------------------------
   9)  FINAL RESULT
-----------------------------------------------------------------*/
SELECT tf."family_id",
       tf.earliest_date                                   AS earliest_publication_date,
       pa.publication_numbers,
       pa.country_codes,
       cpa.cpc_codes,
       ipa.ipc_codes,
       outa.families_cited,
       ina.families_cited_by
FROM   target_families        tf
LEFT   JOIN pub_agg           pa   ON tf."family_id" = pa."family_id"
LEFT   JOIN cpc_agg           cpa  ON tf."family_id" = cpa."family_id"
LEFT   JOIN ipc_agg           ipa  ON tf."family_id" = ipa."family_id"
LEFT   JOIN cited_fams_agg    outa ON tf."family_id" = outa.family_id
LEFT   JOIN incoming_agg      ina  ON tf."family_id" = ina.family_id
ORDER  BY tf."family_id";