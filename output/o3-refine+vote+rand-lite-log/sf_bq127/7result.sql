WITH earliest AS (   -- families whose very first publication appeared in Jan‑2015
    SELECT
        "family_id",
        MIN("publication_date") AS earliest_date
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    GROUP BY "family_id"
    HAVING MIN("publication_date") BETWEEN 20150101 AND 20150131
),

/* all publications that belong to the qualifying families */
fam_pubs AS (
    SELECT
        p."family_id",
        p."publication_number",
        p."country_code",
        p."cpc",
        p."ipc",
        p."citation"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    JOIN earliest e
      ON p."family_id" = e."family_id"
),

/* CPC & IPC codes (one row per code) */
cpc_codes AS (
    SELECT
        fp."family_id",
        UPPER(TRIM(f.value:"code"::STRING)) AS code
    FROM fam_pubs fp,
         LATERAL FLATTEN(input => fp."cpc") f
    WHERE f.value:"code" IS NOT NULL
),
ipc_codes AS (
    SELECT
        fp."family_id",
        UPPER(TRIM(f.value:"code"::STRING)) AS code
    FROM fam_pubs fp,
         LATERAL FLATTEN(input => fp."ipc") f
    WHERE f.value:"code" IS NOT NULL
),

/* ---- families that THIS family cites ---- */
cited_pub_nums AS (
    SELECT DISTINCT
        fp."family_id"                                          AS base_family,
        TRIM(c.value:"publication_number"::STRING)              AS cited_pub
    FROM fam_pubs fp,
         LATERAL FLATTEN(input => fp."citation") c
    WHERE c.value:"publication_number" IS NOT NULL
          AND TRIM(c.value:"publication_number"::STRING) <> ''
),
cited_families AS (
    SELECT DISTINCT
        c.base_family,
        p."family_id"                                           AS cited_family
    FROM cited_pub_nums c
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
      ON p."publication_number" = c.cited_pub
    WHERE p."family_id" <> c.base_family
),

/* ---- families that CITE THIS family (taken from ABS_AND_EMB.cited_by) ---- */
citing_pub_nums AS (
    SELECT DISTINCT
        fp."family_id"                                          AS base_family,
        TRIM(f.value::STRING)                                   AS citing_pub
    FROM fam_pubs fp
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB ae
      ON ae."publication_number" = fp."publication_number"
    ,  LATERAL FLATTEN(input => ae."cited_by") f
    WHERE f.value IS NOT NULL
          AND TRIM(f.value::STRING) <> ''
),
citing_families AS (
    SELECT DISTINCT
        c.base_family,
        p."family_id"                                           AS citing_family
    FROM citing_pub_nums c
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
      ON p."publication_number" = c.citing_pub
    WHERE p."family_id" <> c.base_family
),

/* ---------- aggregate everything ---------- */
final AS (
    SELECT
        e."family_id",
        TO_CHAR(e.earliest_date)                                                    AS earliest_publication_date,
        LISTAGG(DISTINCT fp."publication_number", ',') WITHIN GROUP (ORDER BY fp."publication_number")  AS publication_numbers,
        LISTAGG(DISTINCT fp."country_code",      ',') WITHIN GROUP (ORDER BY fp."country_code")         AS country_codes,
        LISTAGG(DISTINCT cc.code,                ',') WITHIN GROUP (ORDER BY cc.code)                   AS cpc_codes,
        LISTAGG(DISTINCT ic.code,                ',') WITHIN GROUP (ORDER BY ic.code)                   AS ipc_codes,
        LISTAGG(DISTINCT cf.cited_family,        ',') WITHIN GROUP (ORDER BY cf.cited_family)           AS cited_family_ids,
        LISTAGG(DISTINCT cf2.citing_family,      ',') WITHIN GROUP (ORDER BY cf2.citing_family)         AS citing_family_ids
    FROM earliest e
    JOIN fam_pubs      fp  ON fp."family_id" = e."family_id"
    LEFT JOIN cpc_codes cc ON cc."family_id" = e."family_id"
    LEFT JOIN ipc_codes ic ON ic."family_id" = e."family_id"
    LEFT JOIN cited_families cf   ON cf.base_family   = e."family_id"
    LEFT JOIN citing_families cf2 ON cf2.base_family  = e."family_id"
    GROUP BY e."family_id", e.earliest_date
)

SELECT *
FROM final
ORDER BY earliest_publication_date, "family_id";