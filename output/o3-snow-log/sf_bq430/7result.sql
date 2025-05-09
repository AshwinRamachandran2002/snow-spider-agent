/* ---------------------------------------------------------------------------
   Produce qualifying molecule-pairs together with
   – two UUIDs (activity-IDs & SMILES based)
   – change classification of standard values
   – maximum heavy-atom count in the pair
   – latest synthetic publication date
   – highest document-id observed in the pair
--------------------------------------------------------------------------- */
WITH docs_enhanced AS (          -- clean up bibliographic fields
    SELECT  "doc_id"                                 AS doc_id,
            COALESCE(TRY_TO_NUMBER("year"),1970)      AS yr,
            "journal"                                AS journal,
            TRY_TO_NUMBER("first_page")              AS first_pg
    FROM    EBI_CHEMBL.EBI_CHEMBL."DOCS_29"
), ranked_docs AS (              -- percent-rank within (journal, year)
    SELECT  doc_id,
            yr,
            journal,
            first_pg,
            PERCENT_RANK() OVER (PARTITION BY journal, yr
                                 ORDER BY first_pg)  AS pct_rk
    FROM    docs_enhanced
), docs_date AS (                -- synthetic publication date YYYY-MM-DD
    SELECT  doc_id,
            TO_CHAR(yr) || '-' ||
            LPAD(TO_CHAR(CASE WHEN pct_rk IS NULL
                               THEN 1
                               ELSE FLOOR(pct_rk * 11) + 1 END), 2, '0')
            || '-' ||
            LPAD(TO_CHAR(CASE WHEN pct_rk IS NULL
                               THEN 1
                               ELSE MOD(FLOOR(pct_rk * 308), 28) + 1 END), 2, '0')
            AS pub_date
    FROM    ranked_docs
), acts_filtered AS (            -- activities passing base filters
    SELECT  a."activity_id",
            a."assay_id",
            a."standard_type",
            a."standard_relation",
            TRY_TO_NUMBER(a."standard_value")        AS std_val,
            TRY_TO_NUMBER(a."pchembl_value")         AS pchembl,
            a."molregno",
            TRY_TO_NUMBER(cp."heavy_atoms")          AS heavy_atoms,
            a."potential_duplicate",
            TRY_TO_NUMBER(a."doc_id")                AS doc_id,
            cs."canonical_smiles"
    FROM    EBI_CHEMBL.EBI_CHEMBL."ACTIVITIES_29"          a
    JOIN    EBI_CHEMBL.EBI_CHEMBL."COMPOUND_PROPERTIES_29" cp
            ON a."molregno" = cp."molregno"
    JOIN    EBI_CHEMBL.EBI_CHEMBL."COMPOUND_STRUCTURES_33" cs
            ON a."molregno" = cs."molregno"
    WHERE   cp."heavy_atoms" IS NOT NULL
      AND   TRY_TO_NUMBER(cp."heavy_atoms") BETWEEN 10 AND 15
      AND   a."standard_value" IS NOT NULL
      AND   a."pchembl_value" IS NOT NULL
      AND   TRY_TO_NUMBER(a."pchembl_value") > 10
), assays_ok AS (                -- keep assays with <5 rows & <2 duplicates
    SELECT  "assay_id"
    FROM    acts_filtered
    GROUP BY "assay_id"
    HAVING  COUNT(*) < 5
       AND  SUM(CASE WHEN "potential_duplicate" = '1' THEN 1 ELSE 0 END) < 2
), acts_ok AS (                  -- qualifying activity rows
    SELECT  f.*
    FROM    acts_filtered f
    JOIN    assays_ok     u
        ON  f."assay_id" = u."assay_id"
), pairs AS (                    -- unique unordered pairs in same assay/type
    SELECT
        a1."activity_id"                         AS activity_id_1,
        a2."activity_id"                         AS activity_id_2,
        a1."canonical_smiles"                    AS smiles_1,
        a2."canonical_smiles"                    AS smiles_2,
        a1."assay_id",
        a1."standard_type",
        a1."standard_relation"                   AS rel_1,
        a2."standard_relation"                   AS rel_2,
        a1.std_val                               AS val_1,
        a2.std_val                               AS val_2,
        GREATEST(a1.heavy_atoms, a2.heavy_atoms) AS max_heavy_atoms,
        GREATEST(a1.doc_id, a2.doc_id)           AS latest_doc_id,
        a1.doc_id                                AS doc1,
        a2.doc_id                                AS doc2
    FROM   acts_ok a1
    JOIN   acts_ok a2
           ON  a1."assay_id"      = a2."assay_id"
           AND a1."standard_type" = a2."standard_type"
           AND a1."activity_id"   < a2."activity_id"   -- enforce uniqueness
           AND a1."molregno"      <> a2."molregno"
)
SELECT
    p.activity_id_1,
    p.activity_id_2,

    /* UUID from activity IDs (MD5 hex string) */
    MD5('[\"' || p.activity_id_1 || '\",\"' || p.activity_id_2 || '\"]')
        AS activity_pair_uuid,

    /* UUID from canonical SMILES (MD5 hex string) */
    MD5('[\"' || p.smiles_1 || '\",\"' || p.smiles_2 || '\"]')
        AS smiles_pair_uuid,

    /* classify change in standard_value */
    CASE
        WHEN p.val_1 > p.val_2
             AND p.rel_1 IN ('=', '>', '>>', '>=') 
             AND p.rel_2 IN ('=', '<', '<<', '<=')          THEN 'decrease'
        WHEN p.val_1 < p.val_2
             AND p.rel_1 IN ('=', '<', '<<', '<=') 
             AND p.rel_2 IN ('=', '>', '>>', '>=')          THEN 'increase'
        WHEN p.val_1 = p.val_2
             AND p.rel_1 = '=' AND p.rel_2 = '='             THEN 'no-change'
        ELSE 'no-change'
    END                                                     AS standard_change,

    p.max_heavy_atoms,

    /* latest synthetic publication date */
    COALESCE(
        CASE
            WHEN d1.pub_date IS NOT NULL
                 AND (d2.pub_date IS NULL OR d1.pub_date >= d2.pub_date)
            THEN d1.pub_date
            ELSE d2.pub_date
        END,
        '1970-01-01'
    )                                                       AS latest_publication_date,

    p.latest_doc_id
FROM   pairs      p
LEFT JOIN docs_date d1 ON p.doc1 = d1.doc_id
LEFT JOIN docs_date d2 ON p.doc2 = d2.doc_id;