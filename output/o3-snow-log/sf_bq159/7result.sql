/*  Chi–square statistic for association between histological subtype
    and presence of CDH1 mutations in TCGA-BRCA patients
*/
WITH clinical_br AS (          -- BRCA patients with a known histology
    SELECT
        "patient_id"           AS "ParticipantBarcode",
        "histological_type"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE "acronym" = 'BRCA'
      AND "histological_type" IS NOT NULL
      AND "histological_type" NOT ILIKE '%not applicable%'
      AND "histological_type" NOT ILIKE '%not available%'
),    
cdh1_mut AS (                  -- reliable CDH1 mutation calls
    SELECT DISTINCT
        "ParticipantBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study"       = 'BRCA'
      AND "Hugo_Symbol" = 'CDH1'
      AND "FILTER"      = 'PASS'
),    
patient_status AS (            -- mutation status per patient
    SELECT
        c."ParticipantBarcode",
        c."histological_type",
        CASE WHEN m."ParticipantBarcode" IS NOT NULL
             THEN 'Mutated' ELSE 'WildType' END AS "mut_status"
    FROM clinical_br c
    LEFT JOIN cdh1_mut m
           ON c."ParticipantBarcode" = m."ParticipantBarcode"
),    
counts AS (                    -- contingency-table counts
    SELECT
        "histological_type",
        "mut_status",
        COUNT(*) AS n
    FROM patient_status
    GROUP BY
        "histological_type",
        "mut_status"
),    
row_totals AS (                -- keep histologies with >10 total cases
    SELECT
        "histological_type",
        SUM(n) AS row_total
    FROM counts
    GROUP BY "histological_type"
    HAVING SUM(n) > 10
),    
col_totals AS (                -- keep mutation columns with >10 cases
    SELECT
        "mut_status",
        SUM(n) AS col_total
    FROM counts
    GROUP BY "mut_status"
    HAVING SUM(n) > 10
),    
filtered_counts AS (           -- filtered contingency table
    SELECT c.*
    FROM counts            c
    JOIN row_totals    r  USING ("histological_type")
    JOIN col_totals    t  USING ("mut_status")
),    
grand_total AS (               -- grand total of all retained cells
    SELECT SUM(n) AS gtot
    FROM filtered_counts
),    
chi_components AS (            -- (O-E)^2 / E for every cell
    SELECT
        fc."histological_type",
        fc."mut_status",
        fc.n                                AS observed,
        rt.row_total,
        ct.col_total,
        gt.gtot,
        POWER(fc.n - rt.row_total * ct.col_total / gt.gtot, 2)
        / (rt.row_total * ct.col_total / gt.gtot)            AS chi_part
    FROM filtered_counts fc
    JOIN row_totals   rt ON fc."histological_type" = rt."histological_type"
    JOIN col_totals   ct ON fc."mut_status"        = ct."mut_status"
    CROSS JOIN grand_total gt
),    
chi_square AS (                -- final chi-square statistic
    SELECT SUM(chi_part) AS chi_square_value
    FROM chi_components
)
SELECT chi_square_value
FROM chi_square;