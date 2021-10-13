# OpenSAFELY Research

# _OC evaluation work_

Context: Ongoing NHSE/I evaluation of 'Digital First Primary Care: Evaluation of a digital first approach in response to Covid-19', with key objectives:
*	To understand the circumstances and models in which total triage and remote consultations work and don’t work, for whom and why
*	To understand what changes are required to optimise the benefits and mitigate risks for patients and general practices from these new ways of working
*	To inform changes required at a national, regional and local level going forwards

Aim: NHSX to explore the use of OpenSAFELY to support understanding of activity - and its coding - related to the roll-out and use of online consultation systems in England.

Issues:
An initial brief was shared with research questions.
However, difficult to in EHR systems a) define consultations (and sub-modalities) conceptually; b) code consultations consistently (different templates, systems); c) query consultations as units; d) query pathways. Many of the initial asks above require those, as well as further querying capability (incl pathways, concurrent events/codes). Consultation coding is incredibly problematic even with identified codes (SNOMED, ctv3, other pertaining to e.g. "consultation" and "consultation type") because they are not simple consistent physical concepts.

Suggestion to for now restrict analysis to a simple, broad sociodemographic characterisation of cohorts that "have had an OC instance" (according to non-comprehensive but relevant codes) and proceed from there with discussions on further steps.

The overview brief is in the [Documentation folder](./docs).

This is the code and configuration for our report, _Primary care coding activity related to online consultations
Exploratory analysis using OpenSAFELY_

* The final report is [here](./docs), as _docs/Online consultations_v1.0_10Sep21_NHSEIapproved.pdf_ (approved by NHSEI IG) - an updated version of this report may still be included based on stakeholder feedback
* A blogpost on the experience of the pilot use of OpenSAFELY as an external contributor analyst, and highlights of key findings, can be found [here](https://nhsx.github.io/AnalyticsUnit/openSafely_onlineconsultations.html). 
* Raw model outputs, including charts, crosstabs, etc, are in `released_analysis_results/`
* If you are interested in how we defined our variables, take a look at the [study definition](analysis/study_definition.py); this is written in `python`, but non-programmers should be able to understand what is going on there
* If you are interested in how we defined our code lists, look in the [codelists folder](./codelists/).
* Developers and epidemiologists interested in the code should review
[DEVELOPERS.md](./docs/DEVELOPERS.md).

All information is shared suject to the disclaimer below.

# About the OpenSAFELY framework

The OpenSAFELY framework is a new secure analytics platform for
electronic health records research in the NHS.

Instead of requesting access for slices of patient data and
transporting them elsewhere for analysis, the framework supports
developing analytics against dummy data, and then running against the
real data *within the same infrastructure that the data is stored*.
Read more at [OpenSAFELY.org](https://opensafely.org).

The framework is under fast, active development to support rapid
analytics relating to COVID19; we're currently seeking funding to make
it easier for outside collaborators to work with our system.  You can
read our current roadmap [here](ROADMAP.md).

# Disclaimer

This is not an official NHSEI or NHSX site but a repository of technical documents and ongoing work from the NHSX Analytics Unit, made for transparency, collaboration and discussion. The report, outputs and repository have been cleared for open dissemination by NHSEI. Howeber, the narrative include in the report is not necessarily representative of the views of NHSEI/NHSX and any content here should not be regarded as official lines in any form. For more information about NHSX or NHSEI DFPC please visit the official website and FutureNHS channels.
