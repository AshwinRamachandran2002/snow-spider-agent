/*  Distinct studies in the “qin_prostate_repeatability” collection that
    (a) include at least one axial T2‑weighted MR series and
    (b) contain a segmentation whose SegmentedPropertyType mentions
        “Peripheral zone”.                                                    */
WITH t2_studies AS (      -- studies with T2‑weighted MR series
    SELECT DISTINCT
           "StudyInstanceUID"
    FROM   IDC.IDC_V17."DICOM_PIVOT"
    WHERE  "collection_id" = 'qin_prostate_repeatability'
      AND  "Modality"      = 'MR'
      AND  UPPER("SeriesDescription") LIKE '%T2%'             -- T2‑weighted
),     
segmentation_studies AS ( -- studies with “Peripheral zone” segmentations
    SELECT DISTINCT
           dp."StudyInstanceUID"
    FROM   IDC.IDC_V17."SEGMENTATIONS"    s
           JOIN IDC.IDC_V17."DICOM_PIVOT" dp
             ON dp."SeriesInstanceUID" = s."SeriesInstanceUID"
    WHERE  dp."collection_id" = 'qin_prostate_repeatability'
      AND  UPPER(s."SegmentedPropertyType"::STRING) LIKE '%PERIPHERAL%ZONE%'
)      
SELECT DISTINCT
       "StudyInstanceUID"
FROM   t2_studies
INTERSECT
SELECT DISTINCT
       "StudyInstanceUID"
FROM   segmentation_studies;