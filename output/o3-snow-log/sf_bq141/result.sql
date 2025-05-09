/*  Predict TCGA-KIRP clinical stage from MT-CO gene expression  */
WITH clinical AS (                           -- 1. KIRP patients with stage
    SELECT DISTINCT "case_barcode",
                    "clinical_stage"
    FROM (
            SELECT "case_barcode","clinical_stage","disease_code"
            FROM TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0.CLINICAL
            UNION ALL
            SELECT "case_barcode","clinical_stage","disease_code"
            FROM TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0.CLINICAL_V1
            UNION ALL
            SELECT "case_barcode","clinical_stage","disease_code"
            FROM TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0.CLINICAL_V1_1
         ) t
    WHERE  "disease_code" = 'KIRP'
       AND "clinical_stage" IS NOT NULL
),
expr AS (                                  -- 2. MT-CO1/2/3 expression
    SELECT  "case_barcode",
            COALESCE(MAX(CASE WHEN "gene_name" IN ('MT-CO3','MTCO3','COX3')
                              THEN "HTSeq__FPKM_UQ" END),0) AS "MT_CO3",
            COALESCE(MAX(CASE WHEN "gene_name" IN ('MT-CO1','MTCO1','COX1')
                              THEN "HTSeq__FPKM_UQ" END),0) AS "MT_CO1",
            COALESCE(MAX(CASE WHEN "gene_name" IN ('MT-CO2','MTCO2','COX2')
                              THEN "HTSeq__FPKM_UQ" END),0) AS "MT_CO2"
    FROM    TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.RNASEQ_GENE_EXPRESSION
    WHERE   "project_short_name" = 'TCGA-KIRP'
      AND   "gene_name" IN ('MT-CO3','MTCO3','COX3',
                            'MT-CO1','MTCO1','COX1',
                            'MT-CO2','MTCO2','COX2')
    GROUP BY "case_barcode"
),
patient_data AS (                          -- 3. merge stage + expression
    SELECT c."case_barcode",
           c."clinical_stage",
           e."MT_CO3",
           e."MT_CO1",
           e."MT_CO2"
    FROM   clinical c
    JOIN   expr     e USING ("case_barcode")
),
split AS (                                 -- 4. deterministic 90/10 split
    SELECT p.*,
           MOD(ABS(HASH(p."case_barcode")),10) AS "bucket"
    FROM   patient_data p
),
train AS ( SELECT * FROM split WHERE "bucket" < 9 ),  -- 90 %
test  AS ( SELECT * FROM split WHERE "bucket" >= 9 ), -- 10 %
stage_avg AS (                             -- 5. centroid per stage
    SELECT  "clinical_stage",
            AVG("MT_CO3") AS "avg_MT_CO3",
            AVG("MT_CO1") AS "avg_MT_CO1",
            AVG("MT_CO2") AS "avg_MT_CO2"
    FROM    train
    GROUP BY "clinical_stage"
),
distances AS (                             -- 6. distance to each centroid
    SELECT  t."case_barcode",
            s."clinical_stage" AS "candidate_stage",
            SQRT( POWER(t."MT_CO3" - s."avg_MT_CO3",2) +
                  POWER(t."MT_CO1" - s."avg_MT_CO1",2) +
                  POWER(t."MT_CO2" - s."avg_MT_CO2",2) ) AS "dist"
    FROM    test  t
    CROSS JOIN stage_avg s
),
nearest AS (                               -- 7. closest stage per patient
    SELECT  "case_barcode",
            "candidate_stage",
            ROW_NUMBER() OVER (PARTITION BY "case_barcode" ORDER BY "dist") AS rn
    FROM    distances
)
SELECT  "case_barcode",
        "candidate_stage" AS "predicted_clinical_stage"
FROM    nearest
WHERE   rn = 1
ORDER BY "case_barcode";