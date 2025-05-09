/*  Distinct studies in QIN-Prostate-Repeatability collection
    that contain (1) at least one T2‑weighted axial MR series and
    (2) an anatomic‑structure segmentation whose SegmentedPropertyType
        CodeMeaning contains “Peripheral … Zone”.
*/
WITH t2_axial_mr_studies AS (          -- 1. locate T2‑weighted axial MR series
    SELECT DISTINCT "StudyInstanceUID"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE LOWER("collection_id") = 'qin_prostate_repeatability'
      AND "Modality" = 'MR'
      AND "SeriesDescription" IS NOT NULL
      AND (
              UPPER("SeriesDescription") LIKE '%T2%'      -- T2‑weighted
          )
      AND (                                               -- axial naming    
              UPPER("SeriesDescription") LIKE '%AX%'   OR -- “AX”, “AXIAL”, “TRA(nverse)”
              UPPER("SeriesDescription") LIKE '%AXIAL%' OR
              UPPER("SeriesDescription") LIKE '%TRA%'
          )
),
peripheral_zone_studies AS (          -- 2. locate studies with PZ segmentations
    SELECT DISTINCT "StudyInstanceUID"
    FROM IDC.IDC_V17.SEGMENTATIONS
    WHERE
          "SegmentedPropertyType":"CodeMeaning"::STRING ILIKE '%peripheral%'
      AND "SegmentedPropertyType":"CodeMeaning"::STRING ILIKE '%zone%'
)
SELECT DISTINCT t2."StudyInstanceUID"
FROM t2_axial_mr_studies   t2
JOIN peripheral_zone_studies pz
  ON pz."StudyInstanceUID" = t2."StudyInstanceUID"
ORDER BY t2."StudyInstanceUID";