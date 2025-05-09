/*  ---------------------------------------------------------------
    Pairs of different molecules (10–15 heavy-atoms) tested in the
    same assay & standard_type ( <5 qualifying rows / assay ),
    pChEMBL > 10, non-null standard_value, <2 duplicates.
    For every pair (A < B) return the requested fields.
    --------------------------------------------------------------- */
WITH qual_acts AS (            -- 1. qualifying single activities
    SELECT  a."activity_id",
            a."assay_id",
            a."standard_type",
            a."standard_value",
            a."pchembl_value",
            TRY_TO_NUMBER(cp."heavy_atoms")                  AS heavy_atoms,
            a."molregno",
            COALESCE(a."potential_duplicate",0)              AS potential_duplicate,
            a."doc_id"
    FROM   "EBI_CHEMBL"."EBI_CHEMBL"."ACTIVITIES_30"            a
    JOIN   "EBI_CHEMBL"."EBI_CHEMBL"."COMPOUND_PROPERTIES_29"   cp
           ON  cp."molregno" = a."molregno"
    WHERE  a."pchembl_value"   > 10
      AND  a."standard_value" IS NOT NULL
      AND  TRY_TO_NUMBER(cp."heavy_atoms") BETWEEN 10 AND 15
      AND  COALESCE(a."potential_duplicate",0) < 2
),
few_assays AS (              -- 2. keep assays with <5 qualifying rows
    SELECT  "assay_id", "standard_type"
    FROM    qual_acts
    GROUP BY "assay_id", "standard_type"
    HAVING  COUNT(*) < 5
),
filtered AS (                -- 3. qualifying activities in those assays
    SELECT q.*
    FROM   qual_acts  q
    JOIN   few_assays f
      ON  q."assay_id"      = f."assay_id"
      AND q."standard_type" = f."standard_type"
),
pairs AS (                    -- 4. make unique (A<B) pairs, different molecules
    SELECT  LEAST(a1."activity_id", a2."activity_id")   AS act_id_A,
            GREATEST(a1."activity_id", a2."activity_id")AS act_id_B,
            a1."assay_id",
            a1."standard_type"
    FROM    filtered a1
    JOIN    filtered a2
      ON  a1."assay_id"      = a2."assay_id"
      AND a1."standard_type" = a2."standard_type"
      AND a1."activity_id"  < a2."activity_id"
      AND a1."molregno"     <> a2."molregno"
),
annot AS (                    -- 5. add values, structures, heavy-atoms, docs
    SELECT  p.*,
            a1."standard_value"           AS value_A,
            a2."standard_value"           AS value_B,
            a1."molregno"                 AS molregno_A,
            a2."molregno"                 AS molregno_B,
            a1."doc_id"                   AS doc_id_A,
            a2."doc_id"                   AS doc_id_B,
            TRY_TO_NUMBER(cp1."heavy_atoms") AS heavy_A,
            TRY_TO_NUMBER(cp2."heavy_atoms") AS heavy_B,
            cs1."canonical_smiles"        AS smiles_A,
            cs2."canonical_smiles"        AS smiles_B
    FROM    pairs p
    JOIN    filtered a1 ON a1."activity_id" = p.act_id_A
    JOIN    filtered a2 ON a2."activity_id" = p.act_id_B
    JOIN    "EBI_CHEMBL"."EBI_CHEMBL"."COMPOUND_PROPERTIES_29" cp1
           ON cp1."molregno" = a1."molregno"
    JOIN    "EBI_CHEMBL"."EBI_CHEMBL"."COMPOUND_PROPERTIES_29" cp2
           ON cp2."molregno" = a2."molregno"
    JOIN    "EBI_CHEMBL"."EBI_CHEMBL"."COMPOUND_STRUCTURES_30"  cs1
           ON cs1."molregno" = a1."molregno"
    JOIN    "EBI_CHEMBL"."EBI_CHEMBL"."COMPOUND_STRUCTURES_30"  cs2
           ON cs2."molregno" = a2."molregno"
),
classified AS (               -- 6. classify change & misc fields
    SELECT  *,
            CASE
                WHEN value_A > value_B THEN 'decrease'
                WHEN value_A < value_B THEN 'increase'
                ELSE 'no-change'
            END                                    AS std_change,
            GREATEST(heavy_A, heavy_B)             AS max_heavy_atoms,
            GREATEST(doc_id_A, doc_id_B)           AS highest_doc_id
    FROM    annot
)
SELECT  act_id_A,
        act_id_B,
        max_heavy_atoms,
        highest_doc_id,
        '1970-01-01'                                                   AS latest_pub_date,    -- placeholder per instructions
        MD5( TO_JSON(OBJECT_CONSTRUCT('A', act_id_A, 'B', act_id_B))::STRING )  AS mmp_delta_uuid,
        MD5( TO_JSON(OBJECT_CONSTRUCT('A', smiles_A,  'B', smiles_B))::STRING ) AS mmp_smiles_uuid,
        std_change
FROM    classified;