# OpenSAFELY Research Template

This is a template repository for making new OpenSAFELY resarch projects.  Eventually it'll become a framework. To get started, create a new repo using this repo as a template, delete this front matter, and edit the text that follows.

# _OC evaluation work_

Context: Ongoing NHSE/I evaluation of 'Digital First Primary Care: Evaluation of a digital first approach in response to Covid-19', with key objectives:
*	To understand the circumstances and models in which total triage and remote consultations work and don’t work, for whom and why
*	To understand what changes are required to optimise the benefits and mitigate risks for patients and general practices from these new ways of working
*	To inform changes required at a national, regional and local level going forwards

Aim: NHSx to explore the use of OpenSafely to support analysis of primary care provider clinical data for general practices utilising four online consultation systems in England.

Issues:
An initial brief was shared with research questions.
However, difficult to in EHR systems a) define consultations (and sub-modalities) conceptually; b) code consultations consistently (different templates, systems); c) query consultations as units; d) query pathways. Many of the initial asks above require those, as well as further querying capability (incl pathways, concurrent events/codes). Consultation coding is incredibly problematic even with identified codes (SNOMED, ctv3, other pertaining to e.g. "consultation" and "consultation type") because they are not simple consistent physical concepts.

Suggestion to for now restrict analysis to a simple, broad sociodemographic characterisation of cohorts that "have had an OC intance" (according to non-comprehensive but relevant codes) and proceed from there with discussions on further steps.

*	OC instances: for now defined as those where codes eConsultation via online application (procedure) and Consultation via multimedia (procedure) occur.
*	Period: 2020-03-01 to date 
*	Outputs:
*	tbSD: sociodemographics* for cohorts ‘had an OC instance’ vs ‘all registered patients.
*	tbSD: sociodemographics for cohorts ‘had an OC instance’ vs ‘patients with GP consultation;
*	tb01: OC instance rate (OCIR) and unique patient coverage (OCC) by region. For context: GP consultation rate (GPCR).
*	tb02: OCIR and OCC by STP. For context: GP consultation rate (GPCR).
*	tb04: OCIR and OCC by age and gender
*	tb05: OCIR and OCC by ethnicity
*	tb06: OCIR and OCC by region and rurality
*	tb07: OCIR and OCC by care home status
*	tb08: OCIR and OCC by presence of disability
*	tb09: OCIR and OCC by living alone or not (household size=1)


This is the code and configuration for our paper, _name goes here_

* The paper is [here]()
* Raw model outputs, including charts, crosstabs, etc, are in `released_analysis_results/`
* If you are interested in how we defined our variables, take a look at the [study definition](analysis/study_definition.py); this is written in `python`, but non-programmers should be able to understand what is going on there
* If you are interested in how we defined our code lists, look in the [codelists folder](./codelists/).
* Developers and epidemiologists interested in the code should review
[DEVELOPERS.md](./docs/DEVELOPERS.md).

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
