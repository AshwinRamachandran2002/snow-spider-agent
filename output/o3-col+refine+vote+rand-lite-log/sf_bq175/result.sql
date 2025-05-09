/*  Identify chromosome-1 cytobands in the TCGA-KIRC “segment-allelic” data set
    that simultaneously rank within the TOP-11 for  
      – Amplifications  (copy_number ≥ 4)
      – Gains           (copy_number  = 3)
      – Het Deletions   (copy_number  = 1)                                      */

WITH evt AS (          -- map every CNV segment to overlapping cytobands
  SELECT  c."cytoband_name",
          CASE
            WHEN s."copy_number" >= 4 THEN 'Amplification'
            WHEN s."copy_number"  = 3 THEN 'Gain'
            WHEN s."copy_number"  = 1 THEN 'Heterozygous Deletion'
          END                     AS "cnv_class"
  FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23  s
  JOIN TCGA_MITELMAN.PROD.CYTOBANDS_HG38                                      c
    ON s."chromosome" = c."chromosome"
   AND s."start_pos"  < c."hg38_stop"
   AND s."end_pos"    > c."hg38_start"
  WHERE s."chromosome" = 'chr1'               -- chromosome-1 only
    AND s."copy_number" IN (1,3,4,5,6,7,8,9)  -- ignore diploid/other values
),
cnt AS (           -- frequency per cytoband / CNV class
  SELECT  "cytoband_name",
          "cnv_class",
          COUNT(*) AS "event_count"
  FROM    evt
  WHERE   "cnv_class" IS NOT NULL
  GROUP BY "cytoband_name", "cnv_class"
),
rnk AS (           -- rank frequencies within each CNV class (severity proxy)
  SELECT  "cytoband_name",
          "cnv_class",
          "event_count",
          RANK() OVER (PARTITION BY "cnv_class"
                       ORDER BY "event_count" DESC NULLS LAST) AS "freq_rank"
  FROM    cnt
),
top11 AS (         -- keep only cytobands ranking ≤ 11 for every CNV class
  SELECT  "cytoband_name"
  FROM    rnk
  WHERE   "freq_rank" <= 11
  GROUP BY "cytoband_name"
  HAVING  COUNT(DISTINCT "cnv_class") = 3    -- must qualify in all 3 classes
)

SELECT DISTINCT "cytoband_name"
FROM   top11
ORDER  BY "cytoband_name";