WITH t2_axial_studies AS (          -- studies with axial T2‑weighted MR series
    SELECT DISTINCT
           "StudyInstanceUID"
    FROM   IDC.IDC_V17."DICOM_PIVOT"
    WHERE  "collection_id" = 'qin_prostate_repeatability'
      AND  "Modality" = 'MR'
      AND  UPPER("SeriesDescription") LIKE '%T2%'
      AND (UPPER("SeriesDescription") LIKE '%AX%' OR UPPER("SeriesDescription") LIKE '%AXIAL%')
),
peripheral_zone_seg_studies AS (    -- studies that have “Peripheral zone” segmentations
    SELECT DISTINCT
           s."StudyInstanceUID"
    FROM   IDC.IDC_V17."SEGMENTATIONS"  s
    JOIN   IDC.IDC_V17."DICOM_PIVOT"    p
           ON p."StudyInstanceUID" = s."StudyInstanceUID"
    WHERE  p."collection_id" = 'qin_prostate_repeatability'
      AND  LOWER(s."SegmentedPropertyType"::STRING) LIKE '%peripheral zone%'
)
SELECT DISTINCT
       t."StudyInstanceUID"
FROM   t2_axial_studies            t
JOIN   peripheral_zone_seg_studies s
       ON s."StudyInstanceUID" = t."StudyInstanceUID"
ORDER BY
       t."StudyInstanceUID";