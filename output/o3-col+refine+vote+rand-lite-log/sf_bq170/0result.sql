/*  Copy-number–frequency per cytoband for all TCGA-BRCA cases
    (Release 23 allele-specific copy-number segments)                     */

WITH brca_segments AS (      -- 1. all BRCA copy-number segments
    SELECT  "case_barcode",
            "chromosome",
            "start_pos",
            "end_pos",
            "copy_number"
    FROM   "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
    WHERE  "project_short_name" = 'TCGA-BRCA'
),

overlaps AS (                -- 2. base-pair overlap with every cytoband
    SELECT  c."cytoband_name",
            c."hg38_start",
            c."hg38_stop",
            s."case_barcode",
            GREATEST(
                0,
                LEAST(c."hg38_stop",  s."end_pos")
              - GREATEST(c."hg38_start", s."start_pos")
            )                           AS "ov_bp",
            s."copy_number"
    FROM   brca_segments AS s
    JOIN   "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38" AS c
           ON c."chromosome" = s."chromosome"
    WHERE  GREATEST(
              0,
              LEAST(c."hg38_stop",  s."end_pos")
            - GREATEST(c."hg38_start", s."start_pos")
           ) > 0
),

weighted_cn AS (             -- 3. length-weighted, rounded CN per case × cytoband
    SELECT  "cytoband_name",
            "hg38_start",
            "hg38_stop",
            "case_barcode",
            ROUND( SUM("ov_bp" * "copy_number")
                  / NULLIF(SUM("ov_bp"),0) )  AS "rounded_cn"
    FROM    overlaps
    GROUP BY "cytoband_name", "hg38_start", "hg38_stop", "case_barcode"
),

typed AS (                   -- 4. classify CN into CNV type
    SELECT  "cytoband_name",
            "hg38_start",
            "hg38_stop",
            "case_barcode",
            CASE
              WHEN "rounded_cn" = 0 THEN 'Homozygous Deletion'
              WHEN "rounded_cn" = 1 THEN 'Heterozygous Deletion'
              WHEN "rounded_cn" = 2 THEN 'Diploid'
              WHEN "rounded_cn" = 3 THEN 'Gain'
              ELSE                    'Amplification'
            END                           AS "cnv_type"
    FROM    weighted_cn
),

case_totals AS (             -- 5a. total distinct cases per cytoband
    SELECT  "cytoband_name",
            COUNT(DISTINCT "case_barcode") AS "total_cases"
    FROM    typed
    GROUP BY "cytoband_name"
),

type_counts AS (             -- 5b. cases in each CNV type per cytoband
    SELECT  "cytoband_name",
            "hg38_start",
            "hg38_stop",
            "cnv_type",
            COUNT(*)                      AS "cases_in_type"
    FROM    typed
    GROUP BY "cytoband_name", "hg38_start", "hg38_stop", "cnv_type"
)

SELECT  t."cytoband_name",
        t."hg38_start",
        t."hg38_stop",
        t."cnv_type",
        ROUND(100.0 * t."cases_in_type" / c."total_cases", 2) AS "pct_cases"
FROM    type_counts AS t
JOIN    case_totals AS c
  ON    c."cytoband_name" = t."cytoband_name"
ORDER BY t."cytoband_name",
         t."cnv_type";