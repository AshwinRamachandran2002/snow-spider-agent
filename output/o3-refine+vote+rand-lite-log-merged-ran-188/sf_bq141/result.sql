WITH kirp_cases AS (  -- eligible KIRP patients that have a stage
    SELECT 
        "case_barcode",
        "clinical_stage"
    FROM TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0.CLINICAL
    WHERE "disease_code" = 'KIRP'
      AND "clinical_stage" IS NOT NULL
),                                                                   
expr AS (           -- pivot MT-CO* expression to one row per patient
    SELECT  
        r."case_barcode",
        MAX(IFF(r."gene_name" = 'MT-CO1', r."HTSeq__FPKM_UQ", NULL)) AS "MT_CO1",
        MAX(IFF(r."gene_name" = 'MT-CO2', r."HTSeq__FPKM_UQ", NULL)) AS "MT_CO2",
        MAX(IFF(r."gene_name" = 'MT-CO3', r."HTSeq__FPKM_UQ", NULL)) AS "MT_CO3"
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.RNASEQ_GENE_EXPRESSION  r
    JOIN kirp_cases k
      ON r."case_barcode" = k."case_barcode"
    WHERE r."gene_name" IN ('MT-CO1','MT-CO2','MT-CO3')
    GROUP BY r."case_barcode"
),
split AS (          -- hash-based 90/10 train / test split
    SELECT 
        e.*,
        k."clinical_stage",
        MOD(ABS(HASH(e."case_barcode")),10)                AS "bucket"
    FROM expr e
    JOIN kirp_cases k
      ON e."case_barcode" = k."case_barcode"
),
centroids AS (      -- stage-specific training means
    SELECT
        "clinical_stage",
        AVG("MT_CO1") AS "c_MT_CO1",
        AVG("MT_CO2") AS "c_MT_CO2",
        AVG("MT_CO3") AS "c_MT_CO3"
    FROM split
    WHERE "bucket" < 9            -- 90 % TRAIN
    GROUP BY "clinical_stage"
),
test_pts AS (       -- 10 % TEST patients
    SELECT *
    FROM split
    WHERE "bucket" >= 9
),
dists AS (          -- Euclidean distance from each test patient to every centroid
    SELECT
        t."case_barcode",
        c."clinical_stage"                                AS "target_stage",
        SQRT(
            POWER(COALESCE(t."MT_CO1",0) - COALESCE(c."c_MT_CO1",0),2) +
            POWER(COALESCE(t."MT_CO2",0) - COALESCE(c."c_MT_CO2",0),2) +
            POWER(COALESCE(t."MT_CO3",0) - COALESCE(c."c_MT_CO3",0),2)
        )                                                AS "dist"
    FROM test_pts   t
    CROSS JOIN centroids c
),
predictions AS (    -- pick the nearest centroid
    SELECT
        "case_barcode",
        FIRST_VALUE("target_stage") 
            OVER (PARTITION BY "case_barcode" ORDER BY "dist")      AS "predicted_stage"
    FROM dists
)
SELECT DISTINCT
    "case_barcode",
    "predicted_stage"
FROM predictions
ORDER BY "case_barcode";