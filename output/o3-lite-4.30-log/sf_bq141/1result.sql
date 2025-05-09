WITH kirp_clin AS (                               -- patients with KIRP and recorded stage
    SELECT
        "case_barcode",
        "clinical_stage"
    FROM TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0.CLINICAL
    WHERE "disease_code" = 'KIRP'
      AND "clinical_stage" IS NOT NULL
),
kirp_expr AS (                                    -- MT‑CO gene‑expression rows
    SELECT
        "case_barcode",
        "gene_name",
        "HTSeq__FPKM_UQ"
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.RNASEQ_GENE_EXPRESSION
    WHERE "gene_name" IN ('MT-CO1','MT-CO2','MT-CO3')
),
expr_pivot AS (                                   -- pivot to one row per patient
    SELECT
        "case_barcode",
        MAX(CASE WHEN "gene_name" = 'MT-CO1' THEN "HTSeq__FPKM_UQ" END) AS "MT_CO1",
        MAX(CASE WHEN "gene_name" = 'MT-CO2' THEN "HTSeq__FPKM_UQ" END) AS "MT_CO2",
        MAX(CASE WHEN "gene_name" = 'MT-CO3' THEN "HTSeq__FPKM_UQ" END) AS "MT_CO3"
    FROM kirp_expr
    GROUP BY "case_barcode"
),
kirp_data AS (                                    -- join & create deterministic 90/10 split
    SELECT
        kc."case_barcode",
        kc."clinical_stage",
        ep."MT_CO1",
        ep."MT_CO2",
        ep."MT_CO3",
        MOD(ABS(HASH(kc."case_barcode")), 10) AS "split_key"   -- 0‑8 train, 9 test
    FROM kirp_clin kc
    JOIN expr_pivot ep
      ON ep."case_barcode" = kc."case_barcode"
),
train AS (                                        -- 90 % of patients
    SELECT * FROM kirp_data WHERE "split_key" < 9
),
test  AS (                                        -- 10 % of patients
    SELECT * FROM kirp_data WHERE "split_key" = 9
),
stage_centroids AS (                              -- average MT‑CO expression per stage
    SELECT
        "clinical_stage",
        AVG("MT_CO1") AS "CEN_MT_CO1",
        AVG("MT_CO2") AS "CEN_MT_CO2",
        AVG("MT_CO3") AS "CEN_MT_CO3"
    FROM train
    GROUP BY "clinical_stage"
),
distances AS (                                    -- distance of each test pt to each centroid
    SELECT
        t."case_barcode",
        sc."clinical_stage" AS "stage_candidate",
        SQRT(
              POWER(t."MT_CO1" - sc."CEN_MT_CO1", 2) +
              POWER(t."MT_CO2" - sc."CEN_MT_CO2", 2) +
              POWER(t."MT_CO3" - sc."CEN_MT_CO3", 2)
        ) AS "distance"
    FROM test t
    CROSS JOIN stage_centroids sc
)
SELECT
    "case_barcode",
    FIRST_VALUE("stage_candidate") OVER (
        PARTITION BY "case_barcode"
        ORDER BY "distance"
    ) AS "predicted_clinical_stage"
FROM distances
QUALIFY ROW_NUMBER() OVER (PARTITION BY "case_barcode" ORDER BY "distance") = 1
ORDER BY "case_barcode";