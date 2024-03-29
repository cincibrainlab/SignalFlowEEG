# SignalFlowEEG

## A Reproducible EEG Processing Framework

**SignalFlowEEG (SF)** is a comprehensive and versatile framework designed to streamline the processing of Electroencephalograms (EEG). Utilizing an array of different pipelines, SF aims to ensure reproducibility and consistency across EEG studies.

The overarching objective of SF is to generate robust data tables that facilitate summary generation and statistical analysis. These tables can encompass a wide range of EEG features, from intrinsic characteristics to preprocessing steps and sophisticated analysis.

## Core Features

1. **Focus on Data Tables:** 
    SignalFlowEEG generates tables encapsulating diverse aspects of EEG research, including EEG characteristics, preprocessing procedures, and comprehensive analysis.

2. **EEGLAB SET Format Compatibility:** 
    SF employs the universally accepted EEGLAB SET format, providing an efficient data structure for EEG processing and encouraging interoperability with other tools.

3. **Audit Capabilities:** 
    To maintain transparency and accountability, SF provides the ability to perform audits on logged actions. This feature allows researchers to trace back and review the sequence of operations applied on the EEG data.

4. **High-Performance File Formats:** 
    For handling high-dimensional data such as connectivity matrices, SignalFlowEEG adopts high-performance file formats like Apache Parquet. This approach not only ensures data integrity but also facilitates speedy retrieval and efficient storage.

