/* 1️⃣  Filter KIRP patients with known stage
   2️⃣  Gather MT-CO1/2/3 expression and build TRAIN / TEST split (90/10)
   3️⃣  Compute per-stage mean expression on TRAIN
   4️⃣  For every TEST patient calculate Euclidean distance to each stage-mean
   5️⃣  Keep the closest stage as the prediction and return results          */
WITH clinical_filtered AS (  -- KIRP cases that have a stage annotation
    SELECT
        "case_barcode",
        "clinical_stage"
    FROM   TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0."CLINICAL"
    WHERE  "disease_code"   = 'KIRP'
      AND  "clinical_stage" IS NOT NULL
),
expr AS (                    -- pivot MT-CO1/2/3 expression into columns
    SELECT
        "case_barcode",
        MAX(CASE WHEN "gene_name" = 'MT-CO1' THEN "HTSeq__FPKM_UQ" END) AS "MT_CO1",
        MAX(CASE WHEN "gene_name" = 'MT-CO2' THEN "HTSeq__FPKM_UQ" END) AS "MT_CO2",
        MAX(CASE WHEN "gene_name" = 'MT-CO3' THEN "HTSeq__FPKM_UQ" END) AS "MT_CO3"
    FROM   TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0."RNASEQ_GENE_EXPRESSION"
    WHERE  "project_short_name" = 'TCGA-KIRP'
      AND  "gene_name" IN ('MT-CO1','MT-CO2','MT-CO3')
    GROUP  BY "case_barcode"
),
patients AS (                -- join clinical & expression, derive 0-9 hash bucket
    SELECT
        c."case_barcode",
        c."clinical_stage",
        e."MT_CO1",
        e."MT_CO2",
        e."MT_CO3",
        ABS(HASH(c."case_barcode")) % 10 AS "hash_bucket"
    FROM   clinical_filtered c
    JOIN   expr             e  ON c."case_barcode" = e."case_barcode"
),
split AS (                    -- 90 % TRAIN (buckets 0-8) / 10 % TEST (bucket 9)
    SELECT
        *,
        CASE WHEN "hash_bucket" < 9 THEN 'TRAIN' ELSE 'TEST' END AS "subset"
    FROM   patients
),
train_avg AS (               -- stage-specific means on TRAIN patients
    SELECT
        "clinical_stage",
        AVG("MT_CO1") AS "avg_MT_CO1",
        AVG("MT_CO2") AS "avg_MT_CO2",
        AVG("MT_CO3") AS "avg_MT_CO3"
    FROM   split
    WHERE  "subset" = 'TRAIN'
    GROUP  BY "clinical_stage"
),
test_stage_distance AS (     -- Euclidean distance of each TEST patient to every stage centroid
    SELECT
        t."case_barcode",
        s."clinical_stage"              AS "candidate_stage",
        SQRT(
              POW(COALESCE(t."MT_CO1",0) - COALESCE(s."avg_MT_CO1",0), 2)
            + POW(COALESCE(t."MT_CO2",0) - COALESCE(s."avg_MT_CO2",0), 2)
            + POW(COALESCE(t."MT_CO3",0) - COALESCE(s."avg_MT_CO3",0), 2)
        ) AS "dist"
    FROM   split      t
    JOIN   train_avg  s   -- CROSS JOIN each TEST patient to every stage centroid
      ON   t."subset" = 'TEST'
),
predicted AS (               -- pick closest stage for each TEST patient
    SELECT
        "case_barcode",
        "candidate_stage" AS "predicted_clinical_stage"
    FROM   test_stage_distance
    QUALIFY ROW_NUMBER() OVER (PARTITION BY "case_barcode" ORDER BY "dist") = 1
)
SELECT
    "case_barcode",
    "predicted_clinical_stage"
FROM   predicted
ORDER  BY "case_barcode";