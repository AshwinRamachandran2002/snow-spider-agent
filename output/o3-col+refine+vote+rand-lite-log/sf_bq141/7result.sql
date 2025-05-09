/*  Predict KIRP clinical stage from MT-CO1/2/3 RNA-seq profiles                     */
/*  – pick KIRP cases with non-NULL stage                                           */
/*  – 90 / 10 deterministic TRAIN / TEST split via HASH()                           */
/*  – build stage-wise mean vector on TRAIN                                         */
/*  – assign each TEST case to nearest stage (Euclidean)                            */

WITH kirp_stage AS (           -- cases with known stage
    SELECT  "case_barcode",
            "clinical_stage",
            CASE
                WHEN ABS(HASH("case_barcode")) % 10 = 0 THEN 'TEST'   -- ≈10 %
                ELSE 'TRAIN'
            END                                                   AS "set_flag"
    FROM TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0."CLINICAL"
    WHERE "disease_code"   = 'KIRP'
      AND "clinical_stage" IS NOT NULL
),
expr AS (                       -- RNA-seq rows for the three genes
    SELECT  "case_barcode",
            "gene_name",
            "HTSeq__FPKM_UQ"
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0."RNASEQ_GENE_EXPRESSION"
    WHERE "project_short_name" = 'TCGA-KIRP'
      AND "gene_name" IN ('MT-CO1','MT-CO2','MT-CO3')
),
patient_vectors AS (            -- one vector (CO1/2/3) per case
    SELECT  e."case_barcode",
            MAX(CASE WHEN e."gene_name" = 'MT-CO1' THEN e."HTSeq__FPKM_UQ" END) AS "MT_CO1",
            MAX(CASE WHEN e."gene_name" = 'MT-CO2' THEN e."HTSeq__FPKM_UQ" END) AS "MT_CO2",
            MAX(CASE WHEN e."gene_name" = 'MT-CO3' THEN e."HTSeq__FPKM_UQ" END) AS "MT_CO3"
    FROM expr e
    JOIN kirp_stage ks  ON ks."case_barcode" = e."case_barcode"
    GROUP BY e."case_barcode"
),
train_means AS (                -- stage-specific mean vectors (TRAIN only)
    SELECT  ks."clinical_stage",
            AVG(p."MT_CO1") AS "avg_MT_CO1",
            AVG(p."MT_CO2") AS "avg_MT_CO2",
            AVG(p."MT_CO3") AS "avg_MT_CO3"
    FROM patient_vectors p
    JOIN kirp_stage ks  ON ks."case_barcode" = p."case_barcode"
    WHERE ks."set_flag" = 'TRAIN'
    GROUP BY ks."clinical_stage"
),
test_vectors AS (               -- TEST patients’ vectors
    SELECT  p."case_barcode",
            p."MT_CO1",
            p."MT_CO2",
            p."MT_CO3"
    FROM patient_vectors p
    JOIN kirp_stage ks  ON ks."case_barcode" = p."case_barcode"
    WHERE ks."set_flag" = 'TEST'
),
distances AS (                  -- distance from each TEST case to each stage mean
    SELECT  t."case_barcode",
            m."clinical_stage",
            SQRT(
                POWER(t."MT_CO1" - m."avg_MT_CO1", 2) +
                POWER(t."MT_CO2" - m."avg_MT_CO2", 2) +
                POWER(t."MT_CO3" - m."avg_MT_CO3", 2)
            ) AS "euclidean_dist"
    FROM test_vectors t
    CROSS JOIN train_means m
),
final_pred AS (                 -- pick nearest stage per case
    SELECT  d.*,
            ROW_NUMBER() OVER (PARTITION BY d."case_barcode"
                               ORDER BY d."euclidean_dist") AS rn
    FROM distances d
)
SELECT  "case_barcode",
        "clinical_stage" AS "predicted_clinical_stage"
FROM final_pred
WHERE rn = 1
ORDER BY "case_barcode";