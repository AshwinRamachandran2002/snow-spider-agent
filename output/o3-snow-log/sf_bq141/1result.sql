/* ---------------------------------------------------------
   1.  Select KIRP patients with non-NULL clinical_stage
   2.  Pull MT-CO1/2/3 RNA-seq (FPKM-UQ) values
   3.  Aggregate the three genes per patient
   4.  Deterministic 90 / 10 split by HASH(case_barcode)
   5.  Build stage-specific averages from the training set
   6.  For every test patient compute Euclidean distance
       to each stage average and take the nearest one
   7.  Return case_barcode and predicted clinical_stage
   --------------------------------------------------------- */
WITH clinical_filtered AS (          -- step-1
    SELECT
        "case_barcode",
        "clinical_stage"
    FROM TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0.CLINICAL
    WHERE "disease_code" = 'KIRP'
      AND "clinical_stage" IS NOT NULL
),
expr AS (                            -- step-2
    SELECT
        "case_barcode",
        "gene_name",
        "HTSeq__FPKM_UQ"
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.RNASEQ_GENE_EXPRESSION
    WHERE "project_short_name" = 'TCGA-KIRP'
      AND "gene_name" IN ('MT-CO1','MT-CO2','MT-CO3')
),
patient_expr AS (                    -- step-3
    SELECT
        c."case_barcode",
        c."clinical_stage",
        MAX(CASE WHEN e."gene_name"='MT-CO1' THEN e."HTSeq__FPKM_UQ" END) AS "MT_CO1",
        MAX(CASE WHEN e."gene_name"='MT-CO2' THEN e."HTSeq__FPKM_UQ" END) AS "MT_CO2",
        MAX(CASE WHEN e."gene_name"='MT-CO3' THEN e."HTSeq__FPKM_UQ" END) AS "MT_CO3"
    FROM clinical_filtered  c
    JOIN expr               e USING ("case_barcode")
    GROUP BY c."case_barcode", c."clinical_stage"
),
split AS (                           -- step-4
    SELECT
        p.*,
        MOD(ABS(HASH(p."case_barcode")),10) AS "bucket"   -- 0-8 train, 9 test
    FROM patient_expr p
),
train AS (SELECT * FROM split WHERE "bucket" < 9),
test  AS (SELECT * FROM split WHERE "bucket" = 9),
stage_avg AS (                       -- step-5
    SELECT
        "clinical_stage",
        AVG("MT_CO1") AS "avg_MT_CO1",
        AVG("MT_CO2") AS "avg_MT_CO2",
        AVG("MT_CO3") AS "avg_MT_CO3"
    FROM train
    GROUP BY "clinical_stage"
),
distance_calc AS (                   -- step-6
    SELECT
        t."case_barcode",
        s."clinical_stage"                             AS "candidate_stage",
        SQRT( POW(t."MT_CO1" - s."avg_MT_CO1",2)
            + POW(t."MT_CO2" - s."avg_MT_CO2",2)
            + POW(t."MT_CO3" - s."avg_MT_CO3",2) )     AS "dist"
    FROM test t
    CROSS JOIN stage_avg s
),
ranked AS (
    SELECT
        d."case_barcode",
        d."candidate_stage",
        ROW_NUMBER() OVER (PARTITION BY d."case_barcode" ORDER BY d."dist") AS rn
    FROM distance_calc d
)
SELECT
    "case_barcode",
    "candidate_stage"  AS "predicted_clinical_stage"
FROM ranked
WHERE rn = 1
ORDER BY "case_barcode";