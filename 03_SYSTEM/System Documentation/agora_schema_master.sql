-- ============================================================
-- AGORA for Colleges: Assessment + E-Classrecord Platform (PostgreSQL)
-- The original college-management schema, adapted to colleges and
-- extended for the merged AGORA features (45 tables).
-- Multi-college platform: one super admin oversees many colleges.
-- Roles: super_admin > college_admin > teacher > student
-- A class is a course offered in one semester by one teacher;
-- students enroll course by course (no fixed sections).
--
-- Run as the postgres superuser, connected to your database:
--   psql -U postgres -d agora -f agora_schema.sql
--
-- WARNING: the DROP statements below wipe these tables every
-- time the script runs (including the old college-based names,
-- so a development database can be migrated by re-running it).
-- Great for development, remove later.
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;   -- for password hashing (crypt)

-- ------------------------------------------------------------
-- Clean slate (safe to re-run)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS api_requests CASCADE;
DROP TABLE IF EXISTS api_clients CASCADE;
DROP TABLE IF EXISTS agent_prompts CASCADE;
DROP TABLE IF EXISTS class_performance_snapshots CASCADE;
DROP TABLE IF EXISTS retention_analytics CASCADE;
DROP TABLE IF EXISTS retention_settings CASCADE;
DROP TABLE IF EXISTS eclass_scores CASCADE;
DROP TABLE IF EXISTS eclass_columns CASCADE;
DROP TABLE IF EXISTS class_term_weights CASCADE;
DROP TABLE IF EXISTS code_runs CASCADE;
DROP TABLE IF EXISTS rubric_results CASCADE;
DROP TABLE IF EXISTS answers CASCADE;
DROP TABLE IF EXISTS submissions CASCADE;
DROP TABLE IF EXISTS assessment_links CASCADE;
DROP TABLE IF EXISTS code_test_cases CASCADE;
DROP TABLE IF EXISTS coding_problems CASCADE;
DROP TABLE IF EXISTS rubric_criteria CASCADE;
DROP TABLE IF EXISTS questions CASCADE;
DROP TABLE IF EXISTS assessments CASCADE;
DROP TABLE IF EXISTS template_answer_keys CASCADE;
DROP TABLE IF EXISTS template_regions CASCADE;
DROP TABLE IF EXISTS answer_sheet_templates CASCADE;
DROP TABLE IF EXISTS teacher_obe_preferences CASCADE;
DROP TABLE IF EXISTS lesson_plans CASCADE;
DROP TABLE IF EXISTS grade_scale_bands CASCADE;
DROP TABLE IF EXISTS grade_components CASCADE;
DROP TABLE IF EXISTS grading_terms CASCADE;
DROP TABLE IF EXISTS attendance_records CASCADE;
DROP TABLE IF EXISTS account_invites CASCADE;
DROP TABLE IF EXISTS bulk_uploads CASCADE;
DROP TABLE IF EXISTS teacher_bulk_uploads CASCADE;   -- old name, kept so re-running migrates a dev database
DROP TABLE IF EXISTS enrollments CASCADE;
DROP TABLE IF EXISTS classes CASCADE;
DROP TABLE IF EXISTS course_outcomes CASCADE;
DROP TABLE IF EXISTS courses CASCADE;
DROP TABLE IF EXISTS programs CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE IF EXISTS semesters CASCADE;
DROP TABLE IF EXISTS academic_years CASCADE;
DROP TABLE IF EXISTS students CASCADE;
DROP TABLE IF EXISTS teachers CASCADE;
DROP TABLE IF EXISTS college_admins CASCADE;
DROP TABLE IF EXISTS super_admins CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS colleges CASCADE;
DROP TABLE IF EXISTS sections CASCADE;
DROP TABLE IF EXISTS subjects CASCADE;
DROP TABLE IF EXISTS school_years CASCADE;
DROP TABLE IF EXISTS school_admins CASCADE;
DROP TABLE IF EXISTS schools CASCADE;
DROP TYPE  IF EXISTS user_role, gender_type, employment_status, enrollment_status,
    attendance_status, question_type, assessment_delivery, assessment_status, submission_source,
    submission_status, score_source, rubric_verdict, template_layout, code_run_status,
    grade_source, retention_quadrant, agent_run_status, semester_term, course_type, bloom_level,
    review_status, retention_label, agent_task_type, upload_type, essay_scorer;
DROP FUNCTION IF EXISTS set_updated_at();

-- ------------------------------------------------------------
-- Enum types
-- ------------------------------------------------------------
CREATE TYPE user_role         AS ENUM ('super_admin', 'college_admin', 'teacher', 'student');
CREATE TYPE gender_type       AS ENUM ('male', 'female', 'other', 'prefer_not_to_say');
CREATE TYPE employment_status AS ENUM ('full_time', 'part_time', 'visiting');
CREATE TYPE enrollment_status AS ENUM ('enrolled', 'dropped', 'withdrawn', 'completed');

-- AGORA additions: enum types
CREATE TYPE attendance_status   AS ENUM ('present', 'absent', 'late', 'excused');
CREATE TYPE question_type       AS ENUM ('multiple_choice', 'true_false', 'enumeration', 'essay', 'short_answer', 'coding');
CREATE TYPE assessment_delivery AS ENUM ('digital', 'scanned');
CREATE TYPE assessment_status   AS ENUM ('draft', 'approved', 'sent', 'closed');
CREATE TYPE submission_source   AS ENUM ('digital', 'scanned', 'teacher_typed');
CREATE TYPE submission_status   AS ENUM ('in_progress', 'submitted', 'scored', 'reviewed');
CREATE TYPE score_source        AS ENUM ('answer_key', 'model', 'teacher');
CREATE TYPE rubric_verdict      AS ENUM ('met', 'partial', 'not_met');
CREATE TYPE template_layout     AS ENUM ('table', 'cells');
CREATE TYPE code_run_status     AS ENUM ('finished', 'syntax_error', 'runtime_error', 'time_limit_exceeded');
CREATE TYPE grade_source        AS ENUM ('ai_synced', 'ocr_upload', 'manual', 'teacher_override');
CREATE TYPE retention_quadrant  AS ENUM ('safe', 'attendance_risk', 'academic_risk', 'high_risk');
CREATE TYPE agent_run_status    AS ENUM ('running', 'awaiting_review', 'completed', 'failed');

-- College additions: enum types
CREATE TYPE semester_term       AS ENUM ('first', 'second', 'summer');
CREATE TYPE course_type         AS ENUM ('lecture', 'laboratory', 'lecture_laboratory');
CREATE TYPE bloom_level         AS ENUM ('remembering', 'understanding', 'applying', 'analyzing', 'evaluating', 'creating');
CREATE TYPE review_status       AS ENUM ('not_required', 'pending', 'confirmed');
CREATE TYPE retention_label     AS ENUM ('safe', 'for_counseling', 'at_risk');
CREATE TYPE agent_task_type     AS ENUM ('create_quiz', 'send_quiz', 'retrieve_class_info');
CREATE TYPE upload_type         AS ENUM ('teachers', 'students');                    -- what a bulk upload onboards
CREATE TYPE essay_scorer        AS ENUM ('bert_essaychecker', 'qwen');               -- which essay scorer produced a rubric result


-- ------------------------------------------------------------
-- Auto-update "updated_at" on every UPDATE
-- ------------------------------------------------------------
CREATE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- COLLEGES  (added by the super admin)
-- ============================================================
CREATE TABLE colleges (
    id             BIGSERIAL PRIMARY KEY,
    name           VARCHAR(200) NOT NULL,
    college_code    VARCHAR(30)  UNIQUE NOT NULL,     -- e.g. the institution code
    college_type    VARCHAR(50),                      -- state university, private college, etc.
    address_line   VARCHAR(255),
    barangay       VARCHAR(100),
    city           VARCHAR(100),
    province       VARCHAR(100),
    postal_code    VARCHAR(20),
    country        VARCHAR(100) DEFAULT 'Philippines',
    phone          VARCHAR(30),
    email          VARCHAR(255),
    website        VARCHAR(255),
    is_active      BOOLEAN NOT NULL DEFAULT TRUE,
    created_by     BIGINT,                           -- FK added after users exists
    created_at     TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ============================================================
-- USERS  (login accounts for all four roles)
-- Profile details live in super_admins / college_admins /
-- teachers / students, keyed by user_id.
-- ============================================================
CREATE TABLE users (
    id             BIGSERIAL PRIMARY KEY,
    college_id      BIGINT REFERENCES colleges(id) ON DELETE CASCADE,
    role           user_role NOT NULL,
    email          VARCHAR(255) UNIQUE NOT NULL,
    username       VARCHAR(50)  UNIQUE,
    password_hash  TEXT NOT NULL,
    first_name     VARCHAR(100) NOT NULL,
    middle_name    VARCHAR(100),
    last_name      VARCHAR(100) NOT NULL,
    suffix         VARCHAR(20),
    phone          VARCHAR(30),
    avatar_url     TEXT,
    is_active      BOOLEAN NOT NULL DEFAULT TRUE,
    must_change_password BOOLEAN NOT NULL DEFAULT FALSE,   -- forced reset on first login (planned)
    last_login_at  TIMESTAMP,
    created_by     BIGINT REFERENCES users(id) ON DELETE SET NULL,
    created_at     TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMP NOT NULL DEFAULT NOW(),

    -- Super admins belong to no college; everyone else must belong to one.
    CONSTRAINT chk_college_by_role CHECK (
        (role = 'super_admin' AND college_id IS NULL) OR
        (role <> 'super_admin' AND college_id IS NOT NULL)
    ),
    -- Lets profile tables guarantee the user really has that role.
    CONSTRAINT uq_users_id_role UNIQUE (id, role)
);

ALTER TABLE colleges
    ADD CONSTRAINT fk_colleges_created_by
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL;

CREATE INDEX idx_users_college_role ON users (college_id, role);

-- ============================================================
-- COLLEGE STRUCTURE  (managed by the college admin)
-- Academic year > semester > four grading terms. The academic
-- catalog (departments, programs, courses, outcomes) is data.
-- ============================================================

-- Academic years (e.g. 2026-2027)
CREATE TABLE academic_years (
    id          BIGSERIAL PRIMARY KEY,
    college_id  BIGINT NOT NULL REFERENCES colleges(id) ON DELETE CASCADE,
    name        VARCHAR(20) NOT NULL,                -- e.g. '2026-2027'
    start_date  DATE NOT NULL,
    end_date    DATE NOT NULL,
    created_by  BIGINT REFERENCES users(id) ON DELETE SET NULL,
    created_at  TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (college_id, name),
    UNIQUE (id, college_id),
    CHECK (end_date > start_date)
);

-- A term inside an academic year: first, second or summer semester
CREATE TABLE semesters (
    id               BIGSERIAL PRIMARY KEY,
    college_id       BIGINT NOT NULL,
    academic_year_id BIGINT NOT NULL,
    name             semester_term NOT NULL,
    start_date       DATE NOT NULL,
    end_date         DATE NOT NULL,
    is_current       BOOLEAN NOT NULL DEFAULT FALSE,
    created_by       BIGINT REFERENCES users(id) ON DELETE SET NULL,
    created_at       TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (academic_year_id, name),
    UNIQUE (id, college_id),
    CHECK (end_date > start_date),
    -- the semester's college must match its academic year's college
    FOREIGN KEY (academic_year_id, college_id) REFERENCES academic_years (id, college_id) ON DELETE CASCADE
);
-- Only one current semester per college
CREATE UNIQUE INDEX uq_one_current_semester
    ON semesters (college_id) WHERE is_current;

CREATE TABLE departments (
    id          BIGSERIAL PRIMARY KEY,
    college_id  BIGINT NOT NULL REFERENCES colleges(id) ON DELETE CASCADE,
    code        VARCHAR(20) NOT NULL,                -- e.g. 'CCS'
    name        VARCHAR(150) NOT NULL,
    UNIQUE (college_id, code),
    UNIQUE (id, college_id)
);

-- Degree programs offered by a department
CREATE TABLE programs (
    id                 BIGSERIAL PRIMARY KEY,
    college_id         BIGINT NOT NULL,
    department_id      BIGINT NOT NULL,
    code               VARCHAR(20) NOT NULL,         -- e.g. 'BSCS'
    name               VARCHAR(200) NOT NULL,
    degree_level       VARCHAR(30),                  -- bachelor, master, ...
    years_to_complete  SMALLINT CHECK (years_to_complete > 0),
    UNIQUE (college_id, code),
    UNIQUE (id, college_id),
    FOREIGN KEY (department_id, college_id) REFERENCES departments (id, college_id) ON DELETE CASCADE
);

-- Course catalog (replaces subjects)
CREATE TABLE courses (
    id             BIGSERIAL PRIMARY KEY,
    college_id     BIGINT NOT NULL,
    department_id  BIGINT NOT NULL,
    course_code    VARCHAR(30) NOT NULL,             -- e.g. 'CS 301'
    title          VARCHAR(200) NOT NULL,
    description    TEXT,
    units          NUMERIC(3,1) NOT NULL CHECK (units >= 0),
    course_type    course_type NOT NULL DEFAULT 'lecture',
    UNIQUE (college_id, course_code),
    UNIQUE (id, college_id),
    FOREIGN KEY (department_id, college_id) REFERENCES departments (id, college_id) ON DELETE CASCADE
);

-- Course learning outcomes (CLO1, CLO2, ...); can be loaded as ACTS NoteBook goals
CREATE TABLE course_outcomes (
    id            BIGSERIAL PRIMARY KEY,
    course_id     BIGINT NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    outcome_code  VARCHAR(20) NOT NULL,              -- e.g. 'CLO1'
    description   TEXT NOT NULL,
    bloom_level   bloom_level,                       -- target Bloom's level
    position      INT NOT NULL DEFAULT 0,
    UNIQUE (course_id, outcome_code)
);

-- ============================================================
-- ROLE PROFILES
-- ============================================================

-- 1) Super admin
CREATE TABLE super_admins (
    user_id     BIGINT PRIMARY KEY,
    role        user_role NOT NULL DEFAULT 'super_admin' CHECK (role = 'super_admin'),
    notes       TEXT,
    FOREIGN KEY (user_id, role) REFERENCES users (id, role) ON DELETE CASCADE
);

-- 2) College admin (registrar, dean, program head, etc.)
CREATE TABLE college_admins (
    user_id       BIGINT PRIMARY KEY,
    role          user_role NOT NULL DEFAULT 'college_admin' CHECK (role = 'college_admin'),
    employee_no   VARCHAR(50),
    position      VARCHAR(100) NOT NULL DEFAULT 'Registrar',
    date_hired    DATE,
    FOREIGN KEY (user_id, role) REFERENCES users (id, role) ON DELETE CASCADE
);

-- 3) Teacher (belongs to an academic department)
CREATE TABLE teachers (
    user_id            BIGINT PRIMARY KEY,
    role               user_role NOT NULL DEFAULT 'teacher' CHECK (role = 'teacher'),
    employee_no        VARCHAR(50) UNIQUE,
    department_id      BIGINT NOT NULL REFERENCES departments(id) ON DELETE RESTRICT,
    academic_rank      VARCHAR(50),                  -- Instructor, Assistant Professor, ...
    specialization     VARCHAR(100),
    license_no         VARCHAR(50),                  -- e.g. PRC license
    date_hired         DATE,
    employment_status  employment_status NOT NULL DEFAULT 'full_time',
    birthdate          DATE,
    gender             gender_type,
    address            TEXT,
    FOREIGN KEY (user_id, role) REFERENCES users (id, role) ON DELETE CASCADE
);

-- 4) Student (carries a degree program and a year level)
CREATE TABLE students (
    user_id           BIGINT PRIMARY KEY,
    role              user_role NOT NULL DEFAULT 'student' CHECK (role = 'student'),
    student_no        VARCHAR(30) UNIQUE NOT NULL,   -- student number
    program_id        BIGINT NOT NULL REFERENCES programs(id) ON DELETE RESTRICT,
    year_level        SMALLINT NOT NULL DEFAULT 1 CHECK (year_level BETWEEN 1 AND 8),
    birthdate         DATE,
    gender            gender_type,
    address           TEXT,
    emergency_contact VARCHAR(200),
    emergency_phone   VARCHAR(30),
    FOREIGN KEY (user_id, role) REFERENCES users (id, role) ON DELETE CASCADE
);

-- ============================================================
-- CLASSES AND ROSTERS
-- A class is a course offered in one semester by one teacher,
-- with a section code, schedule and room. Classes are assigned
-- by the college. Students enroll course by course, so the old
-- sections table is gone.
-- ============================================================

CREATE TABLE classes (
    id            BIGSERIAL PRIMARY KEY,
    college_id    BIGINT NOT NULL,
    semester_id   BIGINT NOT NULL,
    course_id     BIGINT NOT NULL,
    teacher_id    BIGINT NOT NULL REFERENCES teachers(user_id) ON DELETE RESTRICT,
    section_code  VARCHAR(20) NOT NULL,              -- e.g. 'BSCS 3A'
    schedule      VARCHAR(100),                      -- e.g. 'MWF 8:00-9:00'
    room          VARCHAR(50),
    max_students  INT CHECK (max_students > 0),
    UNIQUE (semester_id, course_id, section_code),
    -- the class's semester and course must belong to the same college
    FOREIGN KEY (semester_id, college_id) REFERENCES semesters (id, college_id) ON DELETE CASCADE,
    FOREIGN KEY (course_id, college_id)   REFERENCES courses (id, college_id)   ON DELETE CASCADE
);
CREATE INDEX idx_classes_teacher_semester ON classes (teacher_id, semester_id);

-- A student's enrollment in one class; the rows of a class are its roster
CREATE TABLE enrollments (
    id           BIGSERIAL PRIMARY KEY,
    student_id   BIGINT NOT NULL REFERENCES students(user_id) ON DELETE CASCADE,
    class_id     BIGINT NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    status       enrollment_status NOT NULL DEFAULT 'enrolled',
    enrolled_by  BIGINT REFERENCES users(id) ON DELETE SET NULL,
    enrolled_at  TIMESTAMP NOT NULL DEFAULT NOW(),
    remarks      TEXT,
    UNIQUE (student_id, class_id)
);
CREATE INDEX idx_enrollments_class ON enrollments (class_id, status);


-- ============================================================
-- AGORA ADDITIONS  (features added after the original schema)
-- ============================================================

-- ------------------------------------------------------------
-- Feature 1: Account provisioning (bulk upload log, invite links)
-- ------------------------------------------------------------
-- Log of every College Admin bulk upload (renamed from teacher_bulk_uploads:
-- it now logs student uploads too)
CREATE TABLE bulk_uploads (
    id            BIGSERIAL PRIMARY KEY,
    college_id    BIGINT NOT NULL REFERENCES colleges(id) ON DELETE CASCADE,
    uploaded_by   BIGINT REFERENCES users(id) ON DELETE SET NULL,   -- the college admin
    upload_type   upload_type NOT NULL,                             -- teachers or students
    file_name     VARCHAR(255),
    total_rows    INT NOT NULL DEFAULT 0,
    created_rows  INT NOT NULL DEFAULT 0,
    failed_rows   INT NOT NULL DEFAULT 0,
    errors        JSONB,                                            -- per-row errors (was error_log)
    created_at    TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Short-lived, single-use invite links (planned replacement for default passwords)
CREATE TABLE account_invites (
    id          BIGSERIAL PRIMARY KEY,
    user_id     BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash  TEXT NOT NULL UNIQUE,
    expires_at  TIMESTAMP NOT NULL,
    used_at     TIMESTAMP,
    created_at  TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------
-- Feature 9: attendance (input to retention analytics)
-- ------------------------------------------------------------
CREATE TABLE attendance_records (
    id               BIGSERIAL PRIMARY KEY,
    class_id         BIGINT NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    student_id       BIGINT NOT NULL REFERENCES students(user_id) ON DELETE CASCADE,
    attendance_date  DATE NOT NULL,
    status           attendance_status NOT NULL,
    recorded_by      BIGINT REFERENCES users(id) ON DELETE SET NULL,
    remarks          TEXT,
    UNIQUE (class_id, student_id, attendance_date)
);
CREATE INDEX idx_attendance_class_date ON attendance_records (class_id, attendance_date);

-- ------------------------------------------------------------
-- Feature 7: E-Classrecord structure
-- ------------------------------------------------------------
-- The four grading terms of a semester (Prelim, Midterm, Pre-Final, Final)
CREATE TABLE grading_terms (
    id           BIGSERIAL PRIMARY KEY,
    semester_id  BIGINT NOT NULL REFERENCES semesters(id) ON DELETE CASCADE,
    name         VARCHAR(30) NOT NULL,
    term_order   SMALLINT NOT NULL CHECK (term_order BETWEEN 1 AND 4),
    UNIQUE (semester_id, name),
    UNIQUE (semester_id, term_order)
);

-- Weighted grade components per class and term (Written Work, Performance Task, ...)
-- The weights of one class + term should add up to 100 (enforced by the application).
CREATE TABLE grade_components (
    id              BIGSERIAL PRIMARY KEY,
    class_id        BIGINT NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    term_id         BIGINT NOT NULL REFERENCES grading_terms(id) ON DELETE CASCADE,
    name            VARCHAR(60) NOT NULL,
    weight_percent  NUMERIC(5,2) NOT NULL CHECK (weight_percent BETWEEN 0 AND 100),
    position        INT NOT NULL DEFAULT 0,
    UNIQUE (class_id, term_id, name)
);

-- Weight of each grading term in a class's Overall Grade (25% each by default,
-- adjustable). The four weights of a class should add up to 100 (enforced by the application).
CREATE TABLE class_term_weights (
    id              BIGSERIAL PRIMARY KEY,
    class_id        BIGINT NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    term_id         BIGINT NOT NULL REFERENCES grading_terms(id) ON DELETE CASCADE,
    weight_percent  NUMERIC(5,2) NOT NULL DEFAULT 25 CHECK (weight_percent BETWEEN 0 AND 100),
    UNIQUE (class_id, term_id)
);

-- The college's own grading scale: percentage ranges mapped to a grade label
-- and grade point (e.g. 1.00 to 5.00 or letter grades). Used to convert the
-- Overall Grade; not linked to individual scores.
CREATE TABLE grade_scale_bands (
    id           BIGSERIAL PRIMARY KEY,
    college_id   BIGINT NOT NULL REFERENCES colleges(id) ON DELETE CASCADE,
    min_percent  NUMERIC(5,2) NOT NULL,
    max_percent  NUMERIC(5,2) NOT NULL,
    grade_label  VARCHAR(10) NOT NULL,
    grade_point  NUMERIC(3,2),
    is_passing   BOOLEAN NOT NULL,
    CHECK (max_percent >= min_percent)
);
CREATE INDEX idx_grade_scale_bands_college ON grade_scale_bands (college_id, min_percent);

-- ------------------------------------------------------------
-- Feature 6: ACTS NoteBook (learning plans)
-- ------------------------------------------------------------
CREATE TABLE lesson_plans (
    id                       BIGSERIAL PRIMARY KEY,
    teacher_id               BIGINT NOT NULL REFERENCES teachers(user_id) ON DELETE RESTRICT,
    class_id                 BIGINT REFERENCES classes(id) ON DELETE SET NULL,
    title                    VARCHAR(200) NOT NULL,
    topics                   JSONB,                    -- target subjects and objectives parsed by the AI
    weekly_goals             JSONB,                    -- weekly learning goals or loaded course outcomes
    uploaded_lecture_files   JSONB,                    -- references only; raw files are never stored
    source_char_counts       JSONB,                    -- characters extracted from each uploaded file (text check)
    ai_generated_obe_content TEXT,                     -- Markdown draft from the local LLM
    docx_export_url          TEXT,
    pdf_export_url           TEXT,
    created_at               TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Saved OBE preferences injected by the Context Assembler node
CREATE TABLE teacher_obe_preferences (
    teacher_id   BIGINT PRIMARY KEY REFERENCES teachers(user_id) ON DELETE CASCADE,
    preferences  JSONB NOT NULL DEFAULT '{}'::jsonb,
    updated_at   TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------
-- Feature 3: Sandbox template mapping
-- ------------------------------------------------------------
CREATE TABLE answer_sheet_templates (
    id                BIGSERIAL PRIMARY KEY,
    college_id         BIGINT NOT NULL REFERENCES colleges(id) ON DELETE CASCADE,
    class_id          BIGINT NOT NULL REFERENCES classes(id) ON DELETE CASCADE,   -- saved within the teacher's classroom
    created_by        BIGINT REFERENCES teachers(user_id) ON DELETE SET NULL,
    name              VARCHAR(150) NOT NULL,
    sample_image_url  TEXT,
    created_at        TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (class_id, name)
);

-- One region of the sheet (e.g. the MCQ grid or the essay box)
CREATE TABLE template_regions (
    id             BIGSERIAL PRIMARY KEY,
    template_id    BIGINT NOT NULL REFERENCES answer_sheet_templates(id) ON DELETE CASCADE,
    question_type  question_type NOT NULL,
    layout         template_layout,                    -- table or individual cells (grid-style items)
    geometry       JSONB NOT NULL,                     -- position, size, rows, columns of the aligned matrix
    first_item_no  INT NOT NULL DEFAULT 1,
    item_count     INT NOT NULL DEFAULT 1 CHECK (item_count > 0),
    position       INT NOT NULL DEFAULT 0
);

-- Answer key attached per cell/item of a region (objective items)
CREATE TABLE template_answer_keys (
    id              BIGSERIAL PRIMARY KEY,
    region_id       BIGINT NOT NULL REFERENCES template_regions(id) ON DELETE CASCADE,
    item_no         INT NOT NULL,
    correct_answer  TEXT NOT NULL,
    points          NUMERIC(6,2) NOT NULL DEFAULT 1,
    UNIQUE (region_id, item_no)
);

-- ------------------------------------------------------------
-- Features 4, 5, 10: assessments, questions, rubrics
-- ------------------------------------------------------------
CREATE TABLE assessments (
    id              BIGSERIAL PRIMARY KEY,
    class_id        BIGINT NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    created_by      BIGINT REFERENCES teachers(user_id) ON DELETE SET NULL,
    lesson_plan_id  BIGINT REFERENCES lesson_plans(id) ON DELETE SET NULL,
    template_id     BIGINT REFERENCES answer_sheet_templates(id) ON DELETE SET NULL,
    term_id         BIGINT REFERENCES grading_terms(id) ON DELETE SET NULL,
    title           VARCHAR(200) NOT NULL,
    format          VARCHAR(30) NOT NULL DEFAULT 'mixed',   -- multiple_choice, essay, coding, mixed, ...
    delivery        assessment_delivery NOT NULL DEFAULT 'digital',
    status          assessment_status NOT NULL DEFAULT 'draft',
    total_points    NUMERIC(8,2),
    deadline        TIMESTAMP,
    max_attempts    INT NOT NULL DEFAULT 1 CHECK (max_attempts > 0),
    -- Essay-scoring parameters (Feature 4). Stored per assessment so older scores can be reproduced.
    mechanics_weight NUMERIC(4,3) NOT NULL DEFAULT 0.400 CHECK (mechanics_weight BETWEEN 0 AND 1),  -- writing quality share of the 0-10 score
    content_weight   NUMERIC(4,3) NOT NULL DEFAULT 0.600 CHECK (content_weight BETWEEN 0 AND 1),    -- rubric coverage share
    full_cutoff      NUMERIC(4,3) NOT NULL DEFAULT 0.700 CHECK (full_cutoff BETWEEN 0 AND 1),       -- similarity >= this earns full criterion points
    partial_cutoff   NUMERIC(4,3) NOT NULL DEFAULT 0.600 CHECK (partial_cutoff BETWEEN 0 AND 1),    -- similarity >= this earns half points
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_scoring_weights_sum CHECK (ABS(mechanics_weight + content_weight - 1) < 0.0005),
    CONSTRAINT chk_scoring_cutoffs     CHECK (partial_cutoff <= full_cutoff)
);
CREATE INDEX idx_assessments_class ON assessments (class_id);

CREATE TABLE questions (
    id             BIGSERIAL PRIMARY KEY,
    assessment_id  BIGINT NOT NULL REFERENCES assessments(id) ON DELETE CASCADE,
    item_no        INT NOT NULL,
    question_type  question_type NOT NULL,
    prompt         TEXT NOT NULL,
    choices        JSONB,                               -- options for multiple choice
    answer_key     JSONB,                               -- objective items: compared directly, no model
    points         NUMERIC(6,2) NOT NULL DEFAULT 1,
    UNIQUE (assessment_id, item_no),
    UNIQUE (id, assessment_id)
);

-- Teacher-written rubric for essay / short-answer questions (content sub-score)
CREATE TABLE rubric_criteria (
    id           BIGSERIAL PRIMARY KEY,
    question_id  BIGINT NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    position     INT NOT NULL DEFAULT 0,
    criterion    TEXT NOT NULL,
    points       NUMERIC(6,2) NOT NULL CHECK (points > 0),
    UNIQUE (question_id, position)
);

-- Coding question (Feature 10)
CREATE TABLE coding_problems (
    id                  BIGSERIAL PRIMARY KEY,
    question_id         BIGINT NOT NULL UNIQUE REFERENCES questions(id) ON DELETE CASCADE,
    language            VARCHAR(20) NOT NULL DEFAULT 'python',
    statement           TEXT,
    starter_code        TEXT,
    time_limit_seconds  INT NOT NULL DEFAULT 5 CHECK (time_limit_seconds > 0)
);

CREATE TABLE code_test_cases (
    id               BIGSERIAL PRIMARY KEY,
    problem_id       BIGINT NOT NULL REFERENCES coding_problems(id) ON DELETE CASCADE,
    position         INT NOT NULL DEFAULT 0,
    stdin            TEXT NOT NULL DEFAULT '',
    expected_output  TEXT NOT NULL,
    points           NUMERIC(6,2) NOT NULL DEFAULT 1,
    is_hidden        BOOLEAN NOT NULL DEFAULT FALSE
);

-- Per-student HMAC-SHA256 secured assessment links (Feature 5, Distributor node)
CREATE TABLE assessment_links (
    id             BIGSERIAL PRIMARY KEY,
    assessment_id  BIGINT NOT NULL REFERENCES assessments(id) ON DELETE CASCADE,
    student_id     BIGINT NOT NULL REFERENCES students(user_id) ON DELETE CASCADE,
    token_hash     TEXT NOT NULL UNIQUE,
    expires_at     TIMESTAMP,
    sent_at        TIMESTAMP,
    opened_at      TIMESTAMP,
    UNIQUE (assessment_id, student_id)
);

-- ------------------------------------------------------------
-- Submissions and per-question answers (Features 4, 5, 10)
-- ------------------------------------------------------------
CREATE TABLE submissions (
    id             BIGSERIAL PRIMARY KEY,
    assessment_id  BIGINT NOT NULL REFERENCES assessments(id) ON DELETE CASCADE,
    student_id     BIGINT NOT NULL REFERENCES students(user_id) ON DELETE CASCADE,
    attempt_no     INT NOT NULL DEFAULT 1 CHECK (attempt_no > 0),
    source         submission_source NOT NULL,           -- digital, scanned sheet, or typed by teacher
    sheet_image_url TEXT,                                -- scanned sheets (Path A)
    status         submission_status NOT NULL DEFAULT 'in_progress',
    total_score    NUMERIC(8,2),
    ai_feedback    TEXT,
    submitted_at   TIMESTAMP,
    created_at     TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (assessment_id, student_id, attempt_no),
    UNIQUE (id, assessment_id)
);
CREATE INDEX idx_submissions_student ON submissions (student_id);

CREATE TABLE answers (
    id                  BIGSERIAL PRIMARY KEY,
    submission_id       BIGINT NOT NULL,
    question_id         BIGINT NOT NULL,
    assessment_id       BIGINT NOT NULL,
    response            JSONB,                           -- digital answer (choice, typed text)
    raw_ocr_text        TEXT,                            -- CS-PADDLE-OCR output (Path A)
    corrected_text      TEXT,                            -- BERT-Spellchecker output
    final_text          TEXT,                            -- text the teacher confirmed or corrected
    ocr_confidence      NUMERIC(4,3) CHECK (ocr_confidence BETWEEN 0 AND 1),
    flagged_for_review  BOOLEAN NOT NULL DEFAULT FALSE,  -- low-confidence words flagged for the teacher
    mechanics_score     NUMERIC(4,3) CHECK (mechanics_score BETWEEN 0 AND 1),
    content_score       NUMERIC(4,3) CHECK (content_score BETWEEN 0 AND 1),
    scoring_params      JSONB,                           -- weights and cutoffs actually used for this answer (reproducibility)
    ai_score            NUMERIC(8,2),                    -- predicted score (before teacher review)
    final_score         NUMERIC(8,2),                    -- score after teacher review or override
    score_source        score_source,
    reviewed_by         BIGINT REFERENCES teachers(user_id) ON DELETE SET NULL,
    review_status       review_status NOT NULL DEFAULT 'not_required',   -- AI essay scores stay 'pending' until confirmed
    confirmed_at        TIMESTAMP,                       -- when the teacher confirmed the score
    UNIQUE (submission_id, question_id),
    FOREIGN KEY (submission_id, assessment_id) REFERENCES submissions (id, assessment_id) ON DELETE CASCADE,
    FOREIGN KEY (question_id, assessment_id)   REFERENCES questions (id, assessment_id)   ON DELETE CASCADE
);

CREATE INDEX idx_answers_pending ON answers (assessment_id) WHERE review_status = 'pending';

-- Per-criterion rubric match for an answer (content sub-score breakdown)
CREATE TABLE rubric_results (
    id              BIGSERIAL PRIMARY KEY,
    answer_id       BIGINT NOT NULL REFERENCES answers(id) ON DELETE CASCADE,
    criterion_id    BIGINT NOT NULL REFERENCES rubric_criteria(id) ON DELETE CASCADE,
    scorer          essay_scorer NOT NULL DEFAULT 'bert_essaychecker',   -- BERT-Essaychecker or Qwen 2.5, shown side by side
    best_match      TEXT,                                -- best-matching sentence from the answer
    similarity      NUMERIC(4,3) CHECK (similarity BETWEEN -1 AND 1),
    verdict         rubric_verdict NOT NULL,
    awarded_points  NUMERIC(6,2) NOT NULL DEFAULT 0,
    reason          TEXT,                                -- short reason for this criterion
    confidence      NUMERIC(4,3) CHECK (confidence BETWEEN 0 AND 1),
    UNIQUE (answer_id, criterion_id, scorer)             -- one result per criterion per scorer
);

CREATE TABLE code_runs (
    id            BIGSERIAL PRIMARY KEY,
    answer_id     BIGINT NOT NULL REFERENCES answers(id) ON DELETE CASCADE,
    source_code   TEXT NOT NULL,
    status        code_run_status NOT NULL,
    stdout        TEXT,
    stderr        TEXT,
    runtime_ms    INT,
    passed_cases  INT NOT NULL DEFAULT 0,
    total_cases   INT NOT NULL DEFAULT 0,
    case_results  JSONB,                                  -- result of each test case (passed, output, runtime)
    ran_at       TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------
-- Feature 7: E-Classrecord grid
-- ------------------------------------------------------------
CREATE TABLE eclass_columns (
    id             BIGSERIAL PRIMARY KEY,
    class_id       BIGINT NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    term_id        BIGINT NOT NULL REFERENCES grading_terms(id) ON DELETE CASCADE,
    component_id   BIGINT REFERENCES grade_components(id) ON DELETE SET NULL,
    assessment_id  BIGINT REFERENCES assessments(id) ON DELETE SET NULL,   -- linked digital/scanned assessment, if any
    title          VARCHAR(150) NOT NULL,
    max_score      NUMERIC(8,2) NOT NULL CHECK (max_score > 0),
    position       INT NOT NULL DEFAULT 0,                                 -- drag-and-drop order
    created_at     TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_eclass_columns_class_term ON eclass_columns (class_id, term_id);

CREATE TABLE eclass_scores (
    id          BIGSERIAL PRIMARY KEY,
    column_id   BIGINT NOT NULL REFERENCES eclass_columns(id) ON DELETE CASCADE,
    student_id  BIGINT NOT NULL REFERENCES students(user_id) ON DELETE CASCADE,
    raw_score   NUMERIC(8,2),
    source      grade_source NOT NULL DEFAULT 'manual',   -- audit trail: AI-synced vs teacher override
    ai_score    NUMERIC(8,2),                              -- original synced value, kept when overridden
    changed_by  BIGINT REFERENCES users(id) ON DELETE SET NULL,
    updated_at  TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (column_id, student_id)
);

-- ------------------------------------------------------------
-- Features 8, 9: analytics
-- ------------------------------------------------------------
CREATE TABLE retention_analytics (
    id                BIGSERIAL PRIMARY KEY,
    student_id        BIGINT NOT NULL REFERENCES students(user_id) ON DELETE CASCADE,
    class_id          BIGINT NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    running_average   NUMERIC(5,2),                        -- from the E-Classrecord
    attendance_rate   NUMERIC(5,2),                        -- from attendance_records
    quadrant          retention_quadrant NOT NULL,         -- 75% threshold on both axes (default)
    label             retention_label NOT NULL,            -- Safe, For Counseling or At Risk
    risk_score        NUMERIC(5,2),
    intervention      TEXT,
    generated_report  TEXT,
    updated_at        TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (student_id, class_id)
);

-- Per-college baselines for the retention matrix (75% by default)
CREATE TABLE retention_settings (
    college_id            BIGINT PRIMARY KEY REFERENCES colleges(id) ON DELETE CASCADE,
    grade_threshold       NUMERIC(5,2) NOT NULL DEFAULT 75 CHECK (grade_threshold BETWEEN 0 AND 100),
    attendance_threshold  NUMERIC(5,2) NOT NULL DEFAULT 75 CHECK (attendance_threshold BETWEEN 0 AND 100),
    updated_at            TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE class_performance_snapshots (
    id             BIGSERIAL PRIMARY KEY,
    class_id       BIGINT NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    assessment_id  BIGINT REFERENCES assessments(id) ON DELETE CASCADE,
    term_id        BIGINT REFERENCES grading_terms(id) ON DELETE SET NULL,
    student_count  INT NOT NULL DEFAULT 0,
    mean_score     NUMERIC(8,2),
    median_score   NUMERIC(8,2),
    std_dev        NUMERIC(8,3),
    highest_score  NUMERIC(8,2),
    lowest_score   NUMERIC(8,2),
    item_stats     JSONB,                                  -- per-question miss rates and difficulty
    summary_text   TEXT,                                   -- optional local-model summary
    computed_at    TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_snapshots_class ON class_performance_snapshots (class_id);

-- ------------------------------------------------------------
-- Feature 5: Agentic Console runs
-- ------------------------------------------------------------
CREATE TABLE agent_prompts (
    id                       BIGSERIAL PRIMARY KEY,
    teacher_id               BIGINT NOT NULL REFERENCES teachers(user_id) ON DELETE CASCADE,
    class_id                 BIGINT REFERENCES classes(id) ON DELETE SET NULL,
    assessment_id            BIGINT REFERENCES assessments(id) ON DELETE SET NULL,
    task_type                agent_task_type NOT NULL,     -- create quiz, send quiz or retrieve class information
    natural_language_request TEXT NOT NULL,
    llm_configuration        JSONB,                        -- Ollama / Qwen 2.5 settings and constraints
    agent_output             JSONB,                        -- outputs of the validation agents before formatting
    status                   agent_run_status NOT NULL DEFAULT 'running',
    created_at               TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------
-- Feature 11: external API access and platform notifications
-- ------------------------------------------------------------
CREATE TABLE api_clients (
    id            BIGSERIAL PRIMARY KEY,
    college_id     BIGINT NOT NULL REFERENCES colleges(id) ON DELETE CASCADE,
    name          VARCHAR(150) NOT NULL,                   -- e.g. the college's VLE
    api_key_hash  TEXT NOT NULL UNIQUE,
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE api_requests (
    id           BIGSERIAL PRIMARY KEY,
    client_id    BIGINT NOT NULL REFERENCES api_clients(id) ON DELETE CASCADE,
    endpoint     VARCHAR(100) NOT NULL,                    -- ocr, spellcheck, essay-score
    status_code  INT,
    duration_ms  INT,
    created_at   TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_api_requests_client ON api_requests (client_id, created_at);

-- Central Interface notifications
CREATE TABLE notifications (
    id          BIGSERIAL PRIMARY KEY,
    user_id     BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type        VARCHAR(50) NOT NULL,
    message     TEXT NOT NULL,
    link_url    TEXT,
    is_read     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_notifications_user ON notifications (user_id, is_read);

-- ============================================================
-- Triggers for updated_at
-- ============================================================
CREATE TRIGGER trg_colleges_updated      BEFORE UPDATE ON colleges      FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_users_updated        BEFORE UPDATE ON users        FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_academic_years_updated BEFORE UPDATE ON academic_years FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_semesters_updated   BEFORE UPDATE ON semesters   FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_lesson_plans_updated     BEFORE UPDATE ON lesson_plans            FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_obe_prefs_updated        BEFORE UPDATE ON teacher_obe_preferences FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_templates_updated        BEFORE UPDATE ON answer_sheet_templates  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_assessments_updated      BEFORE UPDATE ON assessments             FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_eclass_scores_updated    BEFORE UPDATE ON eclass_scores           FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_retention_updated        BEFORE UPDATE ON retention_analytics     FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_retention_settings_updated BEFORE UPDATE ON retention_settings    FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- ============================================================
-- SEED DATA (sample; change the password right away!)
-- ============================================================

-- Super admin
WITH sa AS (
    INSERT INTO users (role, email, username, password_hash, first_name, last_name)
    VALUES ('super_admin', 'superadmin@example.com', 'superadmin',
            crypt('ChangeMe123', gen_salt('bf')), 'Super', 'Admin')
    RETURNING id
)
INSERT INTO super_admins (user_id) SELECT id FROM sa;

-- Sample college, created by the super admin
INSERT INTO colleges (name, college_code, college_type, city, province, created_by)
VALUES ('Sample State College', 'SSC-001', 'state university', 'Davao City', 'Davao del Sur',
        (SELECT id FROM users WHERE username = 'superadmin'));

-- Sample college admin (registrar) for that college
WITH u AS (
    INSERT INTO users (college_id, role, email, username, password_hash, first_name, last_name, created_by)
    VALUES ((SELECT id FROM colleges WHERE college_code = 'SSC-001'),
            'college_admin', 'registrar@example.com', 'registrar',
            crypt('ChangeMe123', gen_salt('bf')), 'Maria', 'Santos',
            (SELECT id FROM users WHERE username = 'superadmin'))
    RETURNING id
)
INSERT INTO college_admins (user_id, position) SELECT id, 'Registrar' FROM u;

-- Sample academic year with its semesters (the first semester is current)
INSERT INTO academic_years (college_id, name, start_date, end_date, created_by)
VALUES ((SELECT id FROM colleges WHERE college_code = 'SSC-001'),
        '2026-2027', '2026-08-03', '2027-05-29',
        (SELECT id FROM users WHERE username = 'registrar'));

INSERT INTO semesters (college_id, academic_year_id, name, start_date, end_date, is_current, created_by)
SELECT ay.college_id, ay.id, v.name::semester_term, v.start_date::date, v.end_date::date, v.is_current,
       (SELECT id FROM users WHERE username = 'registrar')
FROM academic_years ay,
     (VALUES ('first',  '2026-08-03', '2026-12-19', TRUE),
             ('second', '2027-01-11', '2027-05-29', FALSE)) AS v(name, start_date, end_date, is_current)
WHERE ay.name = '2026-2027';

-- The four grading terms of every sample semester
INSERT INTO grading_terms (semester_id, name, term_order)
SELECT sem.id, t.name, t.ord
FROM semesters sem,
     (VALUES ('Prelim', 1), ('Midterm', 2), ('Pre-Final', 3), ('Final', 4)) AS t(name, ord);

-- Default retention baselines (75% on grades and on attendance)
INSERT INTO retention_settings (college_id)
SELECT id FROM colleges WHERE college_code = 'SSC-001';

-- Sample 1.00 to 5.00 grading scale (adjust to the college's own bands)
INSERT INTO grade_scale_bands (college_id, min_percent, max_percent, grade_label, grade_point, is_passing)
SELECT (SELECT id FROM colleges WHERE college_code = 'SSC-001'), b.lo, b.hi, b.lbl, b.gp, b.pass
FROM (VALUES (97, 100, '1.00', 1.00, TRUE), (94, 96.99, '1.25', 1.25, TRUE), (91, 93.99, '1.50', 1.50, TRUE),
             (88, 90.99, '1.75', 1.75, TRUE), (85, 87.99, '2.00', 2.00, TRUE), (82, 84.99, '2.25', 2.25, TRUE),
             (79, 81.99, '2.50', 2.50, TRUE), (76, 78.99, '2.75', 2.75, TRUE), (75, 75.99, '3.00', 3.00, TRUE),
             (0, 74.99, '5.00', 5.00, FALSE)) AS b(lo, hi, lbl, gp, pass);
