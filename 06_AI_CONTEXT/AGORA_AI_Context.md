# AGORA Thesis --- AI Context

## 1. Project identity

**Official full title:** **AGORA - Agent Generator and OCR-based
Recognition Assistant for Quiz Automation, AI-Assisted Learning Plan
Generation, and Student Retention Analytics**

**System name:** AGORA

AGORA is an undergraduate thesis project proposing an adaptable system
blueprint for quiz automation, AI-assisted learning plan generation, and
student retention analytics. ACTS Computer College is the research
setting, but AGORA should not be described as an ACTS-exclusive system
or as universally compatible with every school.

Use the complete official title when a formal document requires the
thesis title. Use **AGORA** when referring to the system in ordinary
discussion.

## 2. How to use this context

Use this file as the concise starting point for AGORA-related tasks.
Read only the files needed for the assigned task rather than loading the
entire repository.

For a specific writing or research task, consult the relevant approved
thesis chapter, system documentation, research sources, consultation
records, or school/adviser template as needed.

### Source priority and conflict handling

When information conflicts, check approval status and dates. Prefer, in
order:

1.  The latest approved thesis documents and project decisions.
2.  The latest approved research scope, objectives, and system
    requirements.
3.  Relevant adviser feedback and consultation records.
4.  Verified external research for claims that require evidence.
5.  Applicable school/adviser templates.
6.  Older drafts and reference theses.
7.  AI-generated suggestions.

A newer approved decision takes priority over an older document. Do not
assume that a mention in a draft, proposal, reference implementation, or
AI-generated suggestion means a feature has been approved or
implemented.

If the conflict cannot be resolved from available sources, state what
conflicts, identify what the sources say, and ask for a decision. Do not
silently choose one version.

## 3. Project purpose and major areas

The project focuses on the following areas:

-   **Quiz and assessment automation:** processing supported physical
    and digital assessment inputs.
-   **AI-assisted learning plan generation:** helping teachers prepare
    learning plans aligned with the project's approved learning-plan
    approach, including Outcome-Based Education (OBE) where specified.
-   **Student retention analytics:** analyzing approved indicators such
    as attendance and assessment performance to support monitoring.
-   **Teacher support tools:** AGORA Agent Console, AGORA Notebook,
    assessment checking, and E-Classrecord.
-   **Teacher review:** allowing teachers to inspect and correct
    uncertain automated results when applicable.

Do not claim that AGORA replaces teacher judgment. Automated results
must remain reviewable where the approved workflow requires teacher
oversight.

## 4. User roles and access

### Super Administrator

Adds and validates institutions.

### School Administrator

Manages institution-level functions, including teacher accounts, class
assignments, school timelines, and grading periods, according to the
approved requirements.

### Teacher

The primary instructional and assessment-management user. Approved
teacher functions include:

-   Using AGORA Agent Console and AGORA Notebook.
-   Creating and processing assessments.
-   Reviewing or correcting uncertain automated results.
-   Working with the E-Classrecord.
-   Monitoring student performance through approved analytics.
-   Uploading student rosters and creating student accounts through the
    approved workflow.

### Student

Uses the isolated Virtual Classroom and other approved student-facing
functions. Students must not be described as having access to AGORA
Agent Console, AGORA Notebook, or the teacher-only AI-Assisted
Assessment Checker.

Use role names and permissions consistently. If a permission is not
established by approved materials, do not invent it.

## 5. Current technical direction

The following directions are established in the current project context.
Do not replace them with alternatives unless the team approves a change.

  -----------------------------------------------------------------------
  Area                    Current direction       Notes
  ----------------------- ----------------------- -----------------------
  OCR                     PaddleOCR               Do not identify
                                                  Tesseract or TrOCR as
                                                  the current OCR engine.

  Locally hosted LLM      Qwen 2.5 through Ollama Do not replace it with
                                                  Gemini or another model
                                                  without an approved
                                                  decision.

  E-Classrecord           Pre-formatted,          Do not describe it as a
                          landscape-oriented      generic web
                          Excel E-Classrecord     spreadsheet.

  Assessment inputs       Physical and digital    Digital text can bypass
                          inputs                  OCR; OCR is relevant to
                                                  image-based physical
                                                  inputs.

  Objective questions     Approved answer-key     Do not describe this as
                          comparison              OMR-based checking.
  -----------------------------------------------------------------------

Other technologies mentioned in project materials include Python/Flask,
OpenCV, CLAHE, ArUco markers, DistilBERT for essay scoring, a T5 model
for question generation, and datasets such as Hewlett/ASAP. Use these
only where relevant and verify their approval and intended role against
the latest project documentation before presenting them as final
architecture or implemented features.

Database selection between MySQL and PostgreSQL, Hugging Face Spaces
hosting, and an online code compiler have appeared in project materials
but should not be treated as settled implementation decisions unless a
newer approved source confirms them. The online code compiler has been
described as a proposed or stretch feature; Judge0 and Piston have been
mentioned as possible options, not automatically as selected services.

## 6. Scope boundaries and exclusions

The following exclusions are established in the current project context:

-   **Do not reintroduce OMR-based objective-question checking.**
-   **Do not reintroduce Learner Reference Number (LRN) as a required
    project identifier.**
-   **Do not make Google Authentication, Google OAuth, Google Login, or
    G-Auth a required feature.**

Objective questions may still be checked through the approved answer-key
comparison process. Answer-key comparison is not OMR.

For account creation, describe the approved workflow in which teachers
upload rosters and create student accounts. Do not add Google
authentication as a requirement.

When writing Scope and Delimitations, explain what the research includes
and excludes. Do not turn the section into a general hardware
specification sheet. Include CPU, RAM, storage, camera, or computer
specifications only when directly relevant to a research boundary and
supported by project sources.

## 7. Assessment processing concepts

Use these terms consistently:

-   **Physical assessment:** an assessment completed on paper and
    captured by photograph or scan for processing.
-   **Digital assessment:** an assessment submitted through an approved
    digital workflow.
-   **Hybrid assessment:** processing both physical and digital
    assessment inputs.
-   **Objective question:** a question with a predefined answer or set
    of acceptable choices.
-   **Constructed response:** a student-generated answer, such as a
    short answer or essay.
-   **Assessment ingestion:** receiving and preparing assessment data
    for processing.
-   **Assessment processing:** interpreting, checking, scoring, or
    organizing assessment information.
-   **OCR (Optical Character Recognition):** extracting machine-readable
    text from an image.

For physical assessment processing, describe the pipeline only to the
level supported by current documentation. Project materials describe
template mapping and image processing before OCR, followed by text
correction/review and applicable scoring. Do not claim every step is
implemented unless implementation evidence confirms it.

Digital text does not need to pass through OCR. Do not conflate
extracting text from an image with checking objective answers against an
answer key.

## 8. Feature status and wording

Clearly distinguish among:

-   **Approved/current:** explicitly confirmed by the team or the latest
    approved project document.
-   **Implemented:** supported by evidence that the feature has actually
    been built.
-   **Planned:** intended for future development.
-   **Proposed:** suggested but not necessarily approved.
-   **Optional/stretch:** considered beyond the core scope or dependent
    on time and feasibility.
-   **Unresolved:** the team has not made a final decision.

Mentioning a technology or feature in this context does not by itself
prove that it is implemented. Do not use "implemented," "supports," or
similar definitive wording without evidence appropriate to the claim.

## 9. Academic writing rules

Use clear English, a formal academic tone, natural undergraduate-level
wording, and direct sentences. Keep explanations specific to AGORA.

Avoid:

-   Generic AI-sounding phrases and inflated claims.
-   Marketing language or claims that the system is universally
    compatible.
-   Repeating the same feature or rationale in several paragraphs.
-   Unnecessary jargon and long disclaimers.
-   Treating proposed features as completed system capabilities.
-   Rewriting established project terminology without a reason.

For Scope and Delimitations, focus on research and system boundaries.
For the Introduction, use citations when they support important factual
claims, statistics, research findings, authoritative definitions, or
specific external claims; do not overload every sentence with citations.

## 10. Research and citation rules

Prefer relevant research published within the most recent five years.
Older sources may be used when they are foundational, original, seminal,
official, or necessary to explain the topic.

Verify sources before citing them. Never invent authors, titles,
publication years, journals, DOIs, statistics, findings, or references.
Make sure each citation actually supports the claim attached to it.
Follow the school/adviser citation format when it is provided.

Clearly separate information drawn from project files, external
research, and AI-generated suggestions. Do not present an AI suggestion
as a project decision or research finding.

## 11. Repository and file-handling rules

-   Read only the files relevant to the assigned task.
-   Do not modify unrelated chapters or documents.
-   Do not delete, rename, commit, or push repository files unless the
    user explicitly requests that action.
-   When asked to work on one chapter section, stay within that
    assignment.
-   Treat previous student theses and reference implementations as
    references only; do not present their features as AGORA features
    unless the team has approved them.
-   Do not refer to a separate "Master Prompt" file as an active source
    of instructions. That file has been removed.

## 12. Final accuracy check

Before returning AGORA-related work, verify that it:

-   Uses the correct full title where required.
-   Matches the latest approved scope and decisions.
-   Uses the correct roles and access boundaries.
-   Identifies PaddleOCR as the current OCR direction and Qwen 2.5
    through Ollama as the current locally hosted LLM direction.
-   Does not reintroduce OMR-based checking, LRN, or required Google
    Authentication.
-   Describes the E-Classrecord as pre-formatted and landscape-oriented
    in Excel.
-   Labels proposed, planned, optional, unresolved, and implemented
    features accurately.
-   Uses verified research and citations.
-   Avoids unnecessary repetition and reads naturally.

**Working rule:** Use established information directly. Label uncertain
status accurately. If sources conflict or a decision is missing, explain
the gap and ask instead of guessing.
